#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
packages=(dist/orca-hardened_*.deb)
if [[ ${#packages[@]} -ne 1 ]]; then
  printf 'Expected exactly one hardened deb, found %s\n' "${#packages[@]}" >&2
  printf '%s\n' "${packages[@]:-}" >&2
  exit 1
fi

package=${packages[0]}
info=$(dpkg-deb --field "$package")
contents=$(dpkg-deb --contents "$package")

grep -q '^ Package: orca-hardened$' <<<" $info" || {
  echo 'Package field is not orca-hardened' >&2
  dpkg-deb --field "$package" Package >&2
  exit 1
}
grep -q '/usr/bin/orca-hardened$' <<<"$contents" || {
  echo 'Hardened CLI symlink is missing' >&2
  exit 1
}
if grep -q '/usr/bin/orca-ide$' <<<"$contents"; then
  echo 'Package must not overwrite the upstream /usr/bin/orca-ide' >&2
  exit 1
fi
grep -q 'orca-hardened-agents.slice$' <<<"$contents" || {
  echo 'systemd user slice is missing' >&2
  exit 1
}

sha256sum "$package" | tee dist/SHA256SUMS
{
  echo "package=$package"
  dpkg-deb --field "$package" Package Version Architecture
} | tee dist/package-metadata.txt
