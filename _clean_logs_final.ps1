$src = 'D:\Projets\HIVMeet\hivmeet\device_run.md'
$dst = 'D:\Projets\HIVMeet\hivmeet\device_run_cleaned.md'
$enc = New-Object System.Text.UTF8Encoding($true)  # keep BOM to match original

$c = [System.IO.File]::ReadAllLines($src, $enc)

function Is-Erase($line) {
  # --- pure system / SDK noise (no app-feature diagnostic value) ---
  if ($line.StartsWith('I/GED')) { return $true }
  if ($line.StartsWith('I/chatty')) { return $true }
  if ($line.StartsWith('D/BufferPoolAccessor2.0')) { return $true }
  if ($line -eq 'D/MediaCodec(16952): flushMediametrics') { return $true }
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
  # StrictMode: keep only the header line, erase every stack frame
  if ($line.StartsWith('D/StrictMode(16952):') -and $line -ne 'D/StrictMode(16952): StrictMode policy violation: android.os.strictmode.NetworkViolation') { return $true }
  if ($line.StartsWith('D/AudioCapabilities') -or $line.StartsWith('W/AudioCapabilities') -or $line.StartsWith('D/VideoCapabilities') -or $line.StartsWith('W/VideoCapabilities')) { return $true }
  # Flutter CLI help block (no diagnostic value for app features)
  if ($line.StartsWith('Flutter run key commands')) { return $true }
  if ($line.StartsWith('r Hot reload')) { return $true }
  if ($line.StartsWith('R Hot restart')) { return $true }
  if ($line.StartsWith('h List all available interactive commands')) { return $true }
  if ($line.StartsWith('d Detach')) { return $true }
  if ($line.StartsWith('c Clear the screen')) { return $true }
  if ($line.StartsWith('q Quit')) { return $true }
  # routine codec / audio plumbing (keep anomaly lines such as "Client returned a buffer it does not own" / "discarded an unknown buffer")
  if ($line.StartsWith('D/AudioTrack')) { return $true }
  if ($line.StartsWith('D/CCodecBufferChannel(16952): [c2.android.aac.decoder#') -and ($line.Contains('Created input block pool') -or $line.Contains('Created output block pool') -or $line.Contains('Configured output block pool'))) { return $true }
  if ($line.StartsWith('I/CCodecBufferChannel(16952): [c2.android.aac.decoder#') -and $line.Contains('Created output block pool')) { return $true }
  # device framework (libMEOW)
  if ($line.StartsWith('D/libMEOW')) { return $true }
  if ($line.StartsWith('I/libMEOW_gift')) { return $true }
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
