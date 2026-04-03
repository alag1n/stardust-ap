$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()
Write-Host "Server started on http://localhost:8080"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    
    $path = $request.Url.LocalPath
    if ($path -eq '/') { $path = '/index.html' }
    
    $filePath = Join-Path "." $path.TrimStart('/')
    
    if (Test-Path $filePath -PathType Leaf) {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
        
        $contentType = "text/html"
        if ($filePath -match '\.js$') { $contentType = "application/javascript" }
        elseif ($filePath -match '\.css$') { $contentType = "text/css" }
        elseif ($filePath -match '\.json$') { $contentType = "application/json" }
        
        $response.ContentType = $contentType
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    } else {
        $response.StatusCode = 404
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    
    $response.Close()
}
