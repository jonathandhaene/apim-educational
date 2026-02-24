#!/usr/bin/env pwsh
#Requires -Version 5.1

$RepoRoot = $PSScriptRoot

function Find-Python {
    $venvWin = Join-Path $RepoRoot ".venv\Scripts\python.exe"
    $venvUnix = Join-Path $RepoRoot ".venv/bin/python"
    if (Test-Path $venvWin) { return $venvWin }
    if (Test-Path $venvUnix) { return $venvUnix }
    if (Get-Command python3 -ErrorAction SilentlyContinue) { return "python3" }
    return "python"
}

function Has-Uv {
    return $null -ne (Get-Command uv -ErrorAction SilentlyContinue)
}

function Ensure-UvEnv {
    if (Has-Uv) {
        Push-Location $RepoRoot
        if (-not (Test-Path ".venv")) { uv venv | Out-Null }
        uv sync | Out-Null
        Pop-Location
    }
}

function Invoke-PyRun {
    param([string[]]$Arguments)
    if (Has-Uv) {
        & uv run python @Arguments
    } else {
        $py = Find-Python
        & $py @Arguments
    }
}

function Invoke-Command-Verbose {
    param([string]$Cmd, [string[]]$CmdArgs)
    Write-Host ""
    Write-Host ">>> $Cmd $($CmdArgs -join ' ')" -ForegroundColor Cyan
    Write-Host ""
    & $Cmd @CmdArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Command exited with code $LASTEXITCODE" -ForegroundColor Red
    }
}

while ($true) {
    Write-Host ""
    Write-Host "APIM Educational Developer CLI" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Setup"
    Write-Host "  1) Install / update Python dependencies"
    Write-Host "  2) Azure CLI login"
    Write-Host ""
    Write-Host "Tests"
    Write-Host "  3) Run pylint (migration tools)"
    Write-Host "  4) Run pytest (migration tools)"
    Write-Host "  5) Run full Python checks (lint + test)"
    Write-Host ""
    Write-Host "Infra"
    Write-Host "  6) Validate Bicep templates"
    Write-Host "  7) Validate Terraform configuration"
    Write-Host ""
    Write-Host "Misc"
    Write-Host "  0) Exit"
    Write-Host ""
    $choice = Read-Host "Select an option"

    switch ($choice) {
        "1" {
            if (Has-Uv) {
                Invoke-Command-Verbose "uv" @("sync")
            } else {
                Write-Host "uv is not installed. Install it from https://docs.astral.sh/uv/ or run: pip install pyyaml pytest pylint pytest-cov coverage" -ForegroundColor Yellow
            }
        }
        "2" {
            $useTenant = Read-Host "Do you want to specify a tenant ID? (y/n)"
            if ($useTenant -eq "y" -or $useTenant -eq "Y") {
                $tenantId = Read-Host "Enter tenant ID"
                if ($tenantId) {
                    Write-Host ""
                    Write-Host ">>> az login --tenant $tenantId" -ForegroundColor Cyan
                    az login --tenant $tenantId
                } else {
                    Write-Host "Tenant ID is required." -ForegroundColor Red
                }
            } else {
                Write-Host ""
                Write-Host ">>> az login" -ForegroundColor Cyan
                az login
            }
        }
        "3" {
            Ensure-UvEnv
            Invoke-PyRun @("-m", "pylint", "--rcfile", "$RepoRoot\.pylintrc", "$RepoRoot\tools\migration\openapi_utils.py")
        }
        "4" {
            Ensure-UvEnv
            Invoke-PyRun @("-m", "pytest", "$RepoRoot\tools\migration\tests\", "-v", "--tb=short")
        }
        "5" {
            Ensure-UvEnv
            Write-Host ""
            Write-Host "=== Pylint ===" -ForegroundColor Cyan
            Invoke-PyRun @("-m", "pylint", "--rcfile", "$RepoRoot\.pylintrc", "$RepoRoot\tools\migration\openapi_utils.py")
            Write-Host ""
            Write-Host "=== Pytest ===" -ForegroundColor Cyan
            Invoke-PyRun @("-m", "pytest", "$RepoRoot\tools\migration\tests\", "-v", "--tb=short",
                "--cov=$RepoRoot\tools\migration", "--cov-report=term-missing")
        }
        "6" {
            if (Get-Command az -ErrorAction SilentlyContinue) {
                Invoke-Command-Verbose "az" @("bicep", "build", "--file", "$RepoRoot\infra\bicep\main.bicep")
            } else {
                Write-Host "Azure CLI is not installed. Install from: https://learn.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
            }
        }
        "7" {
            if (Get-Command terraform -ErrorAction SilentlyContinue) {
                Push-Location "$RepoRoot\infra\terraform"
                terraform validate
                Pop-Location
            } else {
                Write-Host "Terraform is not installed. Install from: https://developer.hashicorp.com/terraform/install" -ForegroundColor Yellow
            }
        }
        "0" {
            Write-Host ""
            Write-Host "Goodbye!" -ForegroundColor Green
            Write-Host ""
            exit 0
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
        }
    }
}
