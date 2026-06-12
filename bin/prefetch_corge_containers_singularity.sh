#!/usr/bin/env bash
set -euo pipefail

: "${NXF_SINGULARITY_CACHEDIR:?Please set NXF_SINGULARITY_CACHEDIR before running this script}"

CACHE="$NXF_SINGULARITY_CACHEDIR"
export NXF_SINGULARITY_CACHEDIR="$CACHE"
export SINGULARITY_CACHEDIR="$CACHE/singularity-oci-cache"

mkdir -p "$NXF_SINGULARITY_CACHEDIR" "$SINGULARITY_CACHEDIR"

singularity cache clean --force || true

pull_image () {
    local uri="$1"
    local name="$2"
    local sif="${CACHE}/${name}.img"

    if [[ -s "$sif" ]]; then
        echo "Already exists: $sif"
    else
        echo "Pulling: $uri"
        singularity pull --force --name "$sif" "$uri"
    fi
}

pull_image 'docker://quay.io/biocontainers/chewbbaca@sha256:39cde3bf7cfa90f5f936998f56c15a2452004e438611002d4a269d9d2812e573' \
'quay.io-biocontainers-chewbbaca@sha256-39cde3bf7cfa90f5f936998f56c15a2452004e438611002d4a269d9d2812e573'

pull_image 'docker://quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' \
'quay.io-biocontainers-pandas@sha256-509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'

pull_image 'docker://quay.io/biocontainers/prodigal@sha256:894e9100527f5c01c2f2c662723dacfe03d7d86f1e5cc5064d00b12e8494a6b1' \
'quay.io-biocontainers-prodigal@sha256-894e9100527f5c01c2f2c662723dacfe03d7d86f1e5cc5064d00b12e8494a6b1'

pull_image 'docker://quay.io/biocontainers/mashtree@sha256:eb96b6f479f0dc4fd5e655c27ba2ce55e94e63ca36e52132e84f76c6de047cdd' \
'quay.io-biocontainers-mashtree@sha256-eb96b6f479f0dc4fd5e655c27ba2ce55e94e63ca36e52132e84f76c6de047cdd'

pull_image 'docker://quay.io/staphb/parsnp@sha256:bb0246aa25118199b721caaba538fad7ee7f64d7e8683faf324dbf37baab0792' \
'quay.io-staphb-parsnp@sha256-bb0246aa25118199b721caaba538fad7ee7f64d7e8683faf324dbf37baab0792'

pull_image 'docker://quay.io/biocontainers/snp-dists@sha256:d6204b4fba8508d9531a69ee705c36756c79d1f8dc85e129e0908c1eaf19d3ac' \
'quay.io-biocontainers-snp-dists@sha256-d6204b4fba8508d9531a69ee705c36756c79d1f8dc85e129e0908c1eaf19d3ac'

pull_image 'docker://quay.io/mdhhs_bioinformatics/reportree@sha256:58b3d79ab21497738a373ff6f763193bb5d044fa4acac4e303bb1c05cf8b4911' \
'quay.io-mdhhs_bioinformatics-reportree@sha256-58b3d79ab21497738a373ff6f763193bb5d044fa4acac4e303bb1c05cf8b4911'

pull_image 'docker://quay.io/biocontainers/snp-sites@sha256:d19b090d52dc1d29b6f862e30cfc38f10fad8cb6954d76ef37298002e1a89213' \
'quay.io-biocontainers-snp-sites@sha256-d19b090d52dc1d29b6f862e30cfc38f10fad8cb6954d76ef37298002e1a89213'

pull_image 'docker://quay.io/biocontainers/iqtree@sha256:604552032e25a7a8d30c8d2f6cbc72b576f2f8159b4d5a0bc17c28dfd9e55511' \
'quay.io-biocontainers-iqtree@sha256-604552032e25a7a8d30c8d2f6cbc72b576f2f8159b4d5a0bc17c28dfd9e55511'

pull_image 'docker://quay.io/biocontainers/r-phytools@sha256:5672e6d56f36bdace102047e4d3aa5f143accd09b5f211eb3503e4da5d411934' \
'quay.io-biocontainers-r-phytools@sha256-5672e6d56f36bdace102047e4d3aa5f143accd09b5f211eb3503e4da5d411934'

pull_image 'docker://quay.io/biocontainers/multiqc@sha256:0fae3fc02ac26ac0ca18475bd363504d2d39db4ff4391c5899648b8490abceee' \
'quay.io-biocontainers-multiqc@sha256-0fae3fc02ac26ac0ca18475bd363504d2d39db4ff4391c5899648b8490abceee'

rm -rf "$NXF_SINGULARITY_CACHEDIR/singularity-oci-cache/"
