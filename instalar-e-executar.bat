@echo off
setlocal EnableExtensions
cd /d "%~dp0.."

echo.
echo === OrçaAgenda - instalacao e execucao local ===
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js nao foi encontrado. Instale a versao LTS em https://nodejs.org/ e execute este arquivo novamente.
  pause
  exit /b 1
)

if not exist ".env" (
  copy /Y ".env.example" ".env" >nul
  echo Arquivo .env criado a partir do exemplo.
  echo Edite .env no Bloco de Notas e preencha somente VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY.
  echo Nao coloque service_role, senha do banco ou tokens de IA neste arquivo.
  pause
)

call npm install
if errorlevel 1 (
  echo A instalacao das dependencias falhou. Veja a mensagem acima.
  pause
  exit /b 1
)

echo.
echo Abrindo servidor local em http://localhost:5173
call npm run dev
endlocal
