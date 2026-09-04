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
package_name=$(dpkg-deb --field "$package" Package)
contents=$(dpkg-deb --contents "$package")

if [[ "$package_name" != "orca-hardened" ]]; then
  printf 'Package field is %q, expected orca-hardened\n' "$package_name" >&2
  exit 1
fi
grep -q '/usr/bin/orca-hardened$' <<<"$contents" || {
  echo 'Hardened CLI entry is missing' >&2
  exit 1
}
if grep -q '/usr/bin/orca-ide$' <<<"$contents"; then
  echo 'Package must not overwrite the upstream /usr/bin/orca-ide' >&2
  exit 1
fi
grep -q 'resources/linux/packaging/orca-hardened-agents.slice$' <<<"$contents" || {
  echo 'systemd user slice resource is missing' >&2
  exit 1
}
grep -q 'resources/linux/packaging/build-manifest.json$' <<<"$contents" || {
  echo 'build manifest is missing' >&2
  exit 1
}

sha256sum "$package" | tee dist/SHA256SUMS
{
  echo "package=$package"
  dpkg-deb --field "$package" Package Version Architecture Installed-Size
} | tee dist/package-metadata.txt
