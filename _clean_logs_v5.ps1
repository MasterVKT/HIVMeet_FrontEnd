$src = 'D:\Projets\HIVMeet\hivmeet\device_run.md'
$dst = 'D:\Projets\HIVMeet\hivmeet\device_run_cleaned.md'
$enc = New-Object System.Text.UTF8Encoding($true)  # keep BOM to match original

$c = [System.IO.File]::ReadAllLines($src, $enc)

# --- DeleteAll rules: pure-system/SDK noise with no app-feature diagnostic value ---
function Is-Erase($line) {
  if ($line.StartsWith('I/GED')) { return $true }
  if ($line.StartsWith('I/chatty')) { return $true }
  if ($line.StartsWith('D/BufferPoolAccessor2.0')) { return $true }
  if ($line.StartsWith('D/MediaCodec(16952): flushMediametrics')) { return $true }
  if ($line.StartsWith('D/ReflectedParamUpdater')) { return $true }
  if ($line.StartsWith('W/Codec2Client(16952): query -- param skipped')) { return $true }
  if ($line.StartsWith('D/SurfaceUtils')) { return $true }
  if ($line.StartsWith('I/BufferQueue')) { return $true }
  if ($line.StartsWith('I/System.out(16952): [OkHttp') -or $line.StartsWith('I/System.out(16952): [okhttp') -or $line.StartsWith('I/System.out(16952): [socket')) { return $true }
  if ($line.Contains('I/MediaCodec(16952): [OMX.MTK.VIDEO.DECODER.AVC] setting surface generation to ')) { return $true }
  if ($line -eq 'D/CCodecConfig(16952): c2 config diff is Dict {') { return $true }
  if ($line.StartsWith('D/CCodecConfig(16952):') -and $line.Contains('c2::')) { return $true }
  if ($line.StartsWith('D/CCodec  (16952):') -and ($line.Contains('int32_t ') -or $line.Contains('string '))) { return $true }
  if ($line -eq 'D/CCodec  (16952): }') { return $true }
  if ($line.StartsWith('D/CCodec  (16952): setup formats input:')) { return $true }
  if ($line.StartsWith('D/CCodec  (16952): } and output:')) { return $true }
  if ($line.StartsWith('D/CCodecBuffers(16952):') -and ($line.Contains('int32_t') -or $line.Contains('string '))) { return $true }
  if ($line.StartsWith('D/CCodecBuffers(16952):') -and $line.TrimEnd().EndsWith('}')) { return $true }
  if ($line.StartsWith('D/CCodecBuffers(16952):') -and $line.Contains('popFromStashAndRegister')) { return $true }
  if ($line.StartsWith('D/StrictMode(16952):') -and $line.Contains('at ')) { return $true }
  if ($line.StartsWith('D/AudioCapabilities') -or $line.StartsWith('W/AudioCapabilities') -or $line.StartsWith('D/VideoCapabilities') -or $line.StartsWith('W/VideoCapabilities')) { return $true }
  return $false
}

# --- KeepFirst dedupe: for any remaining duplicated line keep only the 1st occurrence ---
$out = New-Object System.Collections.Generic.List[string]
$seen = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($line in $c) {
  if (Is-Erase $line) { continue }
  if (-not $seen.Add($line)) { continue }
  [void]$out.Add($line)
}

[System.IO.File]::WriteAllLines($dst, $out, $enc)
"original_lines=$($c.Count)"
"cleaned_lines=$($out.Count)"
"removed=$($c.Count - $out.Count)"
