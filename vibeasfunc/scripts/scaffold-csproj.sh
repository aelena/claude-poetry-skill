#!/usr/bin/env bash
# vibeasfunc: scaffold a minimal .NET 8 console project for translated VBA.
#
# Usage: scripts/scaffold-csproj.sh <project-name> [target-dir]
#
# Creates a clean directory layout with:
#   - a console project (the composition root / boundary)
#   - a class-library project (the pure functional core)
#   - an xunit test project pointing at the core
# Requires `dotnet` on PATH.

set -uo pipefail

NAME="${1:?usage: scaffold-csproj.sh <project-name> [target-dir]}"
DIR="${2:-./$NAME}"

if ! command -v dotnet >/dev/null 2>&1; then
  echo "scaffold: 'dotnet' not on PATH. Install .NET 8 SDK first: https://dotnet.microsoft.com/download" >&2
  exit 2
fi

if [[ -e "$DIR" ]]; then
  echo "scaffold: $DIR already exists, refusing to overwrite" >&2
  exit 3
fi

mkdir -p "$DIR"
cd "$DIR"

dotnet new sln -n "$NAME"

# Pure core
dotnet new classlib -n "${NAME}.Core" -o src/Core
# Boundary / composition root
dotnet new console -n "${NAME}.App"  -o src/App
# Tests
dotnet new xunit  -n "${NAME}.Tests" -o tests/Core.Tests

# Wire references
dotnet sln add src/Core/${NAME}.Core.csproj
dotnet sln add src/App/${NAME}.App.csproj
dotnet sln add tests/Core.Tests/${NAME}.Tests.csproj

dotnet add src/App/${NAME}.App.csproj reference src/Core/${NAME}.Core.csproj
dotnet add tests/Core.Tests/${NAME}.Tests.csproj reference src/Core/${NAME}.Core.csproj

# Add ClosedXML to the App project (boundary I/O for Excel)
dotnet add src/App/${NAME}.App.csproj package ClosedXML

# Optional: add FluentResults to the Core project for Result<T>
# dotnet add src/Core/${NAME}.Core.csproj package FluentResults

cat <<EOF

scaffold: created $DIR with structure:

  $NAME/
  ├── $NAME.sln
  ├── src/
  │   ├── Core/   ← pure functional core (records, pure functions, no I/O)
  │   └── App/    ← composition root + boundary (ClosedXML, Console)
  └── tests/
      └── Core.Tests/

Next steps:
  - cd $DIR
  - put your input/output records and pure functions in src/Core
  - put ExcelReader/ExcelWriter and Main in src/App
  - put unit tests in tests/Core.Tests (no Excel needed)
  - dotnet build && dotnet test
EOF
