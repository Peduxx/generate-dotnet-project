# Script para gerar um projeto .NET baseado em DDD e CQRS no Windows

Write-Host "=== Project generator .NET DDD/CQRS ===" -ForegroundColor Cyan

# Solicitar nome do projeto
$projectName = Read-Host -Prompt "Project name"

# Solicitar tipo de arquitetura
Write-Host "Select the architecture of your project:" -ForegroundColor Yellow
Write-Host "1) Modular Monolith" -ForegroundColor White
Write-Host "2) Microservice" -ForegroundColor White
$archOption = Read-Host -Prompt "Option (1 or 2)"

if ($archOption -eq "1") {
    $architecture = "ModularMonolith"
    # Solicitar módulos para monolito modular
    $moduleInput = Read-Host -Prompt "Modules (split by comma, ex: Identity,Catalog,Order)"
    $modules = $moduleInput -split ','
} 
else {
    $architecture = "Microservice"
    $modules = @()
}

# Solicitar tipo de banco de dados
Write-Host "Select the database type of your project:" -ForegroundColor Yellow
Write-Host "1) Postgres with EF Core" -ForegroundColor White
Write-Host "2) NoSQL with Mongo" -ForegroundColor White
$dbOption = Read-Host -Prompt "Option (1 or 2)"

Write-Host "Creating project $projectName..." -ForegroundColor Green

# Criar diretórios base
New-Item -Path "$projectName" -ItemType Directory -Force | Out-Null
New-Item -Path "$projectName\deployment" -ItemType Directory -Force | Out-Null
New-Item -Path "$projectName\src" -ItemType Directory -Force | Out-Null
New-Item -Path "$projectName\.github\workflows" -ItemType Directory -Force | Out-Null
New-Item -Path "$projectName\docker" -ItemType Directory -Force | Out-Null

# Criar README
$readmeContent = @"
# $projectName

## Descrição
Projeto .NET baseado em arquitetura $architecture com padrões DDD (Domain-Driven Design) e CQRS (Command Query Responsibility Segregation).
"@

Set-Content -Path "$projectName\README.md" -Value $readmeContent

# Entrar no diretório do projeto
Set-Location $projectName

# Criar camada de infraestrutura comum
Write-Host "Creating Infrastructure layer..." -ForegroundColor Green
New-Item -Path "src\$projectName.Infrastructure" -ItemType Directory -Force | Out-Null
dotnet new classlib -o "src\$projectName.Infrastructure" -n "$projectName.Infrastructure"

# Criar estrutura de pastas para infraestrutura
New-Item -Path "src\$projectName.Infrastructure\Data" -ItemType Directory -Force | Out-Null
New-Item -Path "src\$projectName.Infrastructure\Data\Repositories" -ItemType Directory -Force | Out-Null

# Estrutura interna dependendo da arquitetura
if ($architecture -eq "ModularMonolith") {
    # Criar estrutura para monolito modular
    New-Item -Path "src\$projectName.Modules" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\$projectName.Shared" -ItemType Directory -Force | Out-Null
    
    # Criar Gateway com a nova estrutura
    New-Item -Path "src\$projectName.Gateway" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\$projectName.Gateway\Configuration" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\$projectName.Gateway\Middleware" -ItemType Directory -Force | Out-Null
    
    # Criar projetos para cada módulo
    foreach ($module in $modules) {
        $module = $module.Trim()

        # Definir caminhos de pastas
        $moduleBasePath = "src\$projectName.Modules\$projectName.$module"
        $apiPath = "$moduleBasePath\$projectName.$module.Api"
        $corePath = "$moduleBasePath\$projectName.$module.Core"
        $testsPath = "$moduleBasePath\$projectName.$module.Tests"

        # Definir nomes de projetos
        $application = "$projectName.$module.Core.Application"
        $domain = "$projectName.$module.Core.Domain"

        # Criar diretórios principais
        New-Item -Path $moduleBasePath -ItemType Directory -Force | Out-Null
        New-Item -Path $corePath -ItemType Directory -Force | Out-Null
        New-Item -Path $testsPath -ItemType Directory -Force | Out-Null

        # Criar API
        Write-Host "Creating API layer for module $module..." -ForegroundColor Green
        dotnet new webapi -o $apiPath -n "$projectName.$module.Api"

        # Criar pastas na camada de API
        New-Item -Path "$apiPath\Middlewares" -ItemType Directory -Force | Out-Null
        New-Item -Path "$apiPath\Http" -ItemType Directory -Force | Out-Null
        New-Item -Path "$apiPath\Http\Request" -ItemType Directory -Force | Out-Null
        New-Item -Path "$apiPath\Mapping" -ItemType Directory -Force | Out-Null
        New-Item -Path "$apiPath\Controllers" -ItemType Directory -Force | Out-Null

        if ($dbOption -eq "1") {
            # Adicionar pacotes para EF Core
            Write-Host "Adding EF Core packages for module $module..." -ForegroundColor Green
            dotnet add "$apiPath\$projectName.$module.Api.csproj" package Npgsql.EntityFrameworkCore.PostgreSQL
            dotnet add "$apiPath\$projectName.$module.Api.csproj" package Microsoft.EntityFrameworkCore.Design
            Write-Host "Packages added..." -ForegroundColor Green
        } 
        elseif ($dbOption -eq "2") {
            # Adicionar pacotes para MongoDB
            Write-Host "Adding MongoDB packages for module $module..." -ForegroundColor Green
            dotnet add "$apiPath\$projectName.$module.Api.csproj" package MongoDB.Driver
            Write-Host "Packages added..." -ForegroundColor Green
        }

        # Criar camada de aplicação
        Write-Host "Creating application layer for module $module..." -ForegroundColor Green
        $applicationPath = "$corePath\$application"
        dotnet new classlib -o $applicationPath -n $application
        
        # Criar estrutura de pastas para aplicação
        New-Item -Path "$applicationPath\DTOs" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Events" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Commands" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Commands\Validation" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Commands\Handlers" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Queries" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Queries\Handlers" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Queries\Validation" -ItemType Directory -Force | Out-Null
        New-Item -Path "$applicationPath\Mapping" -ItemType Directory -Force | Out-Null

        # Adicionar pacotes para camada de aplicação
        Write-Host "Adding packages for application layer..." -ForegroundColor Green
        dotnet add "$applicationPath\$application.csproj" package MediatR
        dotnet add "$applicationPath\$application.csproj" package FluentValidation
        dotnet add "$applicationPath\$application.csproj" package AutoMapper
        Write-Host "Packages added..." -ForegroundColor Green

        # Criar camada de domínio
        Write-Host "Creating domain layer for module $module..." -ForegroundColor Green
        $domainPath = "$corePath\$domain"
        dotnet new classlib -o $domainPath -n $domain

        # Criar estrutura de pastas para domínio
        New-Item -Path "$domainPath\Abstractions" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\DomainEvents" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\Entities" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\Enums" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\Exceptions" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\Primitives" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\Aggregates" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\Interfaces" -ItemType Directory -Force | Out-Null
        New-Item -Path "$domainPath\ValueObjects" -ItemType Directory -Force | Out-Null

        # Adicionar pacotes para camada de domínio
        Write-Host "Adding packages for domain layer..." -ForegroundColor Green
        dotnet add "$domainPath\$domain.csproj" package MediatR
        Write-Host "Packages added..." -ForegroundColor Green

        # Criar camada de testes
        Write-Host "Creating unit tests for module $module..." -ForegroundColor Green
        $applicationTestsPath = "$testsPath\$application.Tests"
        $domainTestsPath = "$testsPath\$domain.Tests"
        
        dotnet new xunit -o $applicationTestsPath -n "$application.Tests"
        dotnet new xunit -o $domainTestsPath -n "$domain.Tests"
        
        # Criar arquivo de solução se não existir
        if (-not (Test-Path -Path "$projectName.sln")) {
            dotnet new sln
        }
        
        # Adicionar projetos do módulo à solução
        Write-Host "Adding projects to solution for module $module..." -ForegroundColor Green
        dotnet sln add "$apiPath\$projectName.$module.Api.csproj"
        dotnet sln add "$applicationPath\$application.csproj"
        dotnet sln add "$domainPath\$domain.csproj"
        dotnet sln add "$applicationTestsPath\$application.Tests.csproj"
        dotnet sln add "$domainTestsPath\$domain.Tests.csproj"
        
        # Criar Dockerfile para o módulo
        New-Item -Path "docker\$module" -ItemType Directory -Force | Out-Null
        $moduleDockerfileContent = @"
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["$projectName.sln", "./"]
COPY ["$apiPath/$projectName.$module.Api.csproj", "$apiPath/"]
COPY ["$corePath/$application/$application.csproj", "$corePath/$application/"]
COPY ["$corePath/$domain/$domain.csproj", "$corePath/$domain/"]

RUN dotnet restore "$apiPath/$projectName.$module.Api.csproj"
COPY . .
WORKDIR "$apiPath"
RUN dotnet build "$projectName.$module.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "$projectName.$module.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$projectName.$module.Api.dll"]
"@

        Set-Content -Path "docker\$module\Dockerfile" -Value $moduleDockerfileContent
        
        Write-Host "Module $module successfully created..." -ForegroundColor Green
    }
    
    # Criar API Gateway com a nova estrutura
    Write-Host "Creating API Gateway..." -ForegroundColor Green
    dotnet new webapi -o "src\$projectName.Gateway\$projectName.Gateway.Api" -n "$projectName.Gateway.Api"
    
    # Criar projetos compartilhados
    dotnet new classlib -o "src\$projectName.Shared" -n "$projectName.Shared"
    
    # Adicionar projetos à solução
    dotnet sln add "src\$projectName.Gateway\$projectName.Gateway.Api\$projectName.Gateway.Api.csproj"
    dotnet sln add "src\$projectName.Shared\$projectName.Shared.csproj"
    dotnet sln add "src\$projectName.Infrastructure\$projectName.Infrastructure.csproj"
    
    # Criar Dockerfile para o Gateway
    New-Item -Path "docker\Gateway" -ItemType Directory -Force | Out-Null
    $gatewayDockerfileContent = @"
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["$projectName.sln", "./"]
COPY ["src/$projectName.Gateway/$projectName.Gateway.Api/$projectName.Gateway.Api.csproj", "src/$projectName.Gateway/$projectName.Gateway.Api/"]

RUN dotnet restore "src/$projectName.Gateway/$projectName.Gateway.Api/$projectName.Gateway.Api.csproj"
COPY . .
WORKDIR "src/$projectName.Gateway/$projectName.Gateway.Api"
RUN dotnet build "$projectName.Gateway.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "$projectName.Gateway.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$projectName.Gateway.Api.dll"]
"@

    Set-Content -Path "docker\Gateway\Dockerfile" -Value $gatewayDockerfileContent
} 
else {
    # Criar estrutura para microserviço
    New-Item -Path "src\Domain" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Api" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\CrossCutting" -ItemType Directory -Force | Out-Null
    
    # Criar arquivo de solução
    dotnet new sln
    
    # Criar projetos
    dotnet new classlib -o "src\Domain\$projectName.Domain"
    dotnet new classlib -o "src\Application\$projectName.Application"
    dotnet new webapi -o "src\Api\$projectName.Api"
    dotnet new classlib -o "src\CrossCutting\$projectName.CrossCutting"
    
    # Criar estrutura de pastas para domínio
    New-Item -Path "src\Domain\$projectName.Domain\Abstractions" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\DomainEvents" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\Entities" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\Enums" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\Exceptions" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\Primitives" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\Aggregates" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\Interfaces" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Domain\$projectName.Domain\ValueObjects" -ItemType Directory -Force | Out-Null
    
    # Criar estrutura de pastas para aplicação
    New-Item -Path "src\Application\$projectName.Application\DTOs" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Events" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Commands" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Commands\Validation" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Commands\Handlers" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Queries" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Queries\Handlers" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Queries\Validation" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Application\$projectName.Application\Mapping" -ItemType Directory -Force | Out-Null
    
    # Criar estrutura de pastas para API
    New-Item -Path "src\Api\$projectName.Api\Middlewares" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Api\$projectName.Api\Http" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Api\$projectName.Api\Http\Request" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Api\$projectName.Api\Mapping" -ItemType Directory -Force | Out-Null
    New-Item -Path "src\Api\$projectName.Api\Controllers" -ItemType Directory -Force | Out-Null
    
    # Adicionar pacotes
    dotnet add "src\Application\$projectName.Application\$projectName.Application.csproj" package MediatR
    dotnet add "src\Application\$projectName.Application\$projectName.Application.csproj" package FluentValidation
    dotnet add "src\Application\$projectName.Application\$projectName.Application.csproj" package AutoMapper
    dotnet add "src\Domain\$projectName.Domain\$projectName.Domain.csproj" package MediatR
    
    if ($dbOption -eq "1") {
        # Adicionar pacotes para EF Core
        dotnet add "src\$projectName.Infrastructure\$projectName.Infrastructure.csproj" package Npgsql.EntityFrameworkCore.PostgreSQL
        dotnet add "src\$projectName.Infrastructure\$projectName.Infrastructure.csproj" package Microsoft.EntityFrameworkCore.Design
    } 
    elseif ($dbOption -eq "2") {
        # Adicionar pacotes para MongoDB
        dotnet add "src\$projectName.Infrastructure\$projectName.Infrastructure.csproj" package MongoDB.Driver
    }
    
    # Adicionar projetos à solução
    dotnet sln add "src\Domain\$projectName.Domain\$projectName.Domain.csproj"
    dotnet sln add "src\Application\$projectName.Application\$projectName.Application.csproj"
    dotnet sln add "src\$projectName.Infrastructure\$projectName.Infrastructure.csproj"
    dotnet sln add "src\Api\$projectName.Api\$projectName.Api.csproj"
    dotnet sln add "src\CrossCutting\$projectName.CrossCutting\$projectName.CrossCutting.csproj"
    
    # Criar Dockerfile para o microserviço
    New-Item -Path "docker\$projectName" -ItemType Directory -Force | Out-Null
    $microserviceDockerfileContent = @"
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["$projectName.sln", "./"]
COPY ["src/Api/$projectName.Api/$projectName.Api.csproj", "src/Api/$projectName.Api/"]
COPY ["src/Application/$projectName.Application/$projectName.Application.csproj", "src/Application/$projectName.Application/"]
COPY ["src/Domain/$projectName.Domain/$projectName.Domain.csproj", "src/Domain/$projectName.Domain/"]
COPY ["src/$projectName.Infrastructure/$projectName.Infrastructure.csproj", "src/$projectName.Infrastructure/"]
COPY ["src/CrossCutting/$projectName.CrossCutting/$projectName.CrossCutting.csproj", "src/CrossCutting/$projectName.CrossCutting/"]

RUN dotnet restore "src/Api/$projectName.Api/$projectName.Api.csproj"
COPY . .
WORKDIR "/src/Api/$projectName.Api"
RUN dotnet build "$projectName.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "$projectName.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$projectName.Api.dll"]
"@

    Set-Content -Path "docker\$projectName\Dockerfile" -Value $microserviceDockerfileContent
}

# Criar GitHub Actions workflow
$workflowContent = @'
name: .NET Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 9.0.x
    - name: Restore dependencies
      run: dotnet restore
    - name: Build
      run: dotnet build --no-restore
    - name: Test
      run: dotnet test --no-build --verbosity normal
'@

Set-Content -Path ".github\workflows\dotnet.yml" -Value $workflowContent

# Criar docker-compose.yml na pasta docker
$dockerComposeContent = @'
version: '3.8'

services:
'@

# Adicionar serviços ao docker-compose baseado na arquitetura
if ($architecture -eq "ModularMonolith") {
    # Adicionar entrada para API Gateway
    $gatewayService = @"

  gateway:
    build:
      context: ..
      dockerfile: docker/Gateway/Dockerfile
    ports:
      - "5000:80"
      - "5001:443"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    depends_on:
      - database
"@
    $dockerComposeContent += $gatewayService
    
    # Adicionar entrada para cada módulo
    foreach ($module in $modules) {
        $module = $module.Trim()
        $moduleService = @"

  $($module.ToLower()):
    build:
      context: ..
      dockerfile: docker/$module/Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    depends_on:
      - database
"@
        $dockerComposeContent += $moduleService
    }
} 
else {
    # Adicionar entrada para microserviço
    $microserviceService = @"

  api:
    build:
      context: ..
      dockerfile: docker/$projectName/Dockerfile
    ports:
      - "5000:80"
      - "5001:443"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    depends_on:
      - database
"@
    $dockerComposeContent += $microserviceService
}

# Adicionar banco de dados ao docker-compose
$databaseService = ""
if ($dbOption -eq "1") {
    $databaseService = @"

  database:
    image: postgres:latest
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=${projectName}db
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
"@
} 
elseif ($dbOption -eq "2") {
    $databaseService = @"

  database:
    image: mongo:latest
    environment:
      - MONGO_INITDB_DATABASE=${projectName}db
    ports:
      - "27017:27017"
    volumes:
      - mongodata:/data/db

volumes:
  mongodata:
"@
}

$dockerComposeContent += $databaseService

Set-Content -Path "docker\docker-compose.yml" -Value $dockerComposeContent

# Criar .gitignore
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/github/gitignore/main/VisualStudio.gitignore" -OutFile ".gitignore"

Write-Host "Projeto $projectName criado com sucesso!" -ForegroundColor Green
Write-Host "Execute: cd $projectName; dotnet restore" -ForegroundColor Cyan