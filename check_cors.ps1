# Check CORS configuration on Yandex Cloud Storage
$bucket = "daren"
$endpoint = "https://storage.yandexcloud.net"

# Get current CORS using AWS CLI compatible API
$response = Invoke-RestMethod -Uri "$endpoint/$bucket/?cors" `
    -Method GET `
    -Headers @{"Host" = "storage.yandexcloud.net"}

$response.CORSRules.CORSRule | Format-List
