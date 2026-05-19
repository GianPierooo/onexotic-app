# Script para crear usuario Luis Felipe en Supabase
# Prerequisito: obtener SERVICE_ROLE_KEY en
# Supabase Dashboard → Project Settings → API → service_role key
#
# Ejecutar con:
#   $env:SERVICE_ROLE_KEY = "eyJ..."
#   .\scripts\create_user_luis_felipe.ps1

$SUPABASE_URL    = "https://gxzajbxumilshvrpwcnx.supabase.co"
$SERVICE_ROLE_KEY = $env:SERVICE_ROLE_KEY

if (-not $SERVICE_ROLE_KEY) {
    Write-Error "Falta SERVICE_ROLE_KEY. Ejecútalo como:`n  `$env:SERVICE_ROLE_KEY = 'eyJ...'; .\scripts\create_user_luis_felipe.ps1"
    exit 1
}

$headers = @{
    "apikey"        = $SERVICE_ROLE_KEY
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "Content-Type"  = "application/json"
}

# 1. Crear usuario en Auth
Write-Host "Creando usuario en Auth..."
$authBody = @{
    email          = "felipevillafana2005@gmail.com"
    password       = "OnExotic2025!"
    email_confirm  = $true
    user_metadata  = @{ nombre = "Luis Felipe"; rol = "ceo" }
} | ConvertTo-Json

$authResponse = Invoke-RestMethod `
    -Uri    "$SUPABASE_URL/auth/v1/admin/users" `
    -Method POST `
    -Headers $headers `
    -Body   $authBody

$userId = $authResponse.id
Write-Host "Usuario Auth creado: $userId"

# 2. Espera breve para que el trigger handle_new_user cree la fila en public.users
Start-Sleep -Seconds 2

# 3. Actualizar public.users con datos completos
Write-Host "Actualizando public.users..."
$profileBody = @{
    nombre   = "Luis Felipe"
    apellido = "Villafana"
    rol      = "ceo"
    horario  = "09:00 - 19:00"
    activo   = $true
    tema     = "dark"
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri    "$SUPABASE_URL/rest/v1/users?id=eq.$userId" `
    -Method PATCH `
    -Headers @{
        "apikey"        = $SERVICE_ROLE_KEY
        "Authorization" = "Bearer $SERVICE_ROLE_KEY"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=representation"
    } `
    -Body $profileBody | Out-Null

Write-Host "Usuario creado exitosamente:"
Write-Host "  Email    : felipevillafana2005@gmail.com"
Write-Host "  Nombre   : Luis Felipe Villafana"
Write-Host "  Rol      : CEO"
Write-Host "  Password : OnExotic2025! (pedir que lo cambie al primer login)"
