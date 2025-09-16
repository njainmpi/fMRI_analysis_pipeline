# Helper: print usage/help
_signal_change_map_usage() {
cat <<'EOF'
Usage:
  Signal_Change_Map -i <input_4d.nii[.gz]> -s <baseline_start> -e <baseline_end> [-o <out_prefix>]
  Signal_Change_Map <input_4d.nii[.gz]> <baseline_start> <baseline_end> [out_prefix]

Description:
  Compute a % signal-change 4D dataset relative to a baseline window and
  produce a sliding-window mean 4D output across time.

Required arguments:
  -i, --input         Path to input 4D NIfTI (.nii or .nii.gz)
  -s, --start         Baseline start TR index (0-based, inclusive)
  -e, --end           Baseline end TR index (inclusive)

Optional:
  -o, --out-prefix    Prefix for outputs (default: "SCM_cleaned")
  -h, --help          Show this help and exit

Outputs:
  baseline_image_<s>_to_<e>.nii.gz
      Mean baseline image from TR s..e

  <prefix>.nii.gz
      % signal-change normalized 4D dataset

  <prefix>_sliding_avg_win_<win>.nii.gz
      4D stack of sliding-window means:
        sub-brick 0 = mean(0..win-1), 1 = mean(1..win), ..., last = mean(last..nt-1)

Examples:
  # With flags
  Signal_Change_Map -i SCM_input.nii.gz -s 0 -e 100 -o SCM_trialA

  # Positional (same as above)
  Signal_Change_Map SCM_input.nii.gz 0 100 SCM_trialA
EOF
}

# Helper: check a required command exists
_need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' not found in PATH." >&2; return 127; }; }

Signal_Change_Map () {
        # Show help if asked explicitly
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        _signal_change_map_usage; return 0
        fi

        # ---------------------------
        # Parse CLI (flags or positionals)
        # ---------------------------
        local input="" base_start="" base_end="" out_prefix="SCM_cleaned"

        if [[ "$1" == -* ]]; then
        # Flag style
        while [[ $# -gt 0 ]]; do
        case "$1" in
                -i|--input)       input="$2"; shift 2 ;;
                -s|--start)       base_start="$2"; shift 2 ;;
                -e|--end)         base_end="$2"; shift 2 ;;
                -o|--out-prefix)  out_prefix="$2"; shift 2 ;;
                -h|--help)        _signal_change_map_usage; return 0 ;;
                --)               shift; break ;;
                -*)               echo "ERROR: Unknown option: $1" >&2; _signal_change_map_usage; return 2 ;;
                *)                break ;;
        esac
        done
        else
        # Positional fallback: input start end [out_prefix]
        input="${1:-}"; base_start="${2:-}"; base_end="${3:-}"; [[ -n "${4:-}" ]] && out_prefix="$4"
        fi

        # If any required arg missing → help
        if [[ -z "$input" || -z "$base_start" || -z "$base_end" ]]; then
        echo "ERROR: Missing required arguments." >&2
        _signal_change_map_usage; return 2
        fi

        # ---------------------------
        # Validate inputs & env
        # ---------------------------
        if [[ ! -f "$input" ]]; then
        echo "ERROR: Input file '$input' not found." >&2; return 1
        fi
        if [[ "$input" != *.nii && "$input" != *.nii.gz ]]; then
        echo "ERROR: Input must be a NIfTI file (.nii or .nii.gz)." >&2; return 1
        fi
        if ! [[ "$base_start" =~ ^[0-9]+$ && "$base_end" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Baseline start/end must be integers." >&2; return 1
        fi
        if (( base_end <= base_start )); then
        echo "ERROR: baseline_end must be greater than baseline_start." >&2; return 1
        fi

        # External tool checks (AFNI/FSL)
        _need 3dTstat || return $?
        _need 3dinfo  || return $?
        _need 3dTcat  || return $?
        _need fslmaths || return $?

        # ---------------------------
        # Processing
        # ---------------------------
        local win=$(( base_end - base_start ))
        local step=1
        local base_label="${base_start}_to_${base_end}"
        local out_sliding="${out_prefix}_sliding_avg_win_${win}.nii.gz"
        local out_psc="${out_prefix}.nii.gz"

        echo ">>> Normalizing to % signal change..."

        #Making mask to create even cleaner SCM
        fslmaths ${input} -thrp 45 -bin autoclean_mask_${input}
        fslmaths ${input} -mas autoclean_mask_${input} autocleaned_${input}
        fslmaths autocleaned_${input} -sub "baseline_image_${base_label}.nii.gz" -div "baseline_image_${base_label}.nii.gz" -mul 100 "$out_psc_${base_label}"

        echo ">>> Baseline-normalized file ready: $out_psc"

        local nt
        nt=$(3dinfo -nt "$out_psc")
        local last=$(( nt - win ))
        if (( last < 0 )); then
        echo "ERROR: nt($nt) < win($win). Choose a shorter baseline window or check data." >&2
        return 1
        fi

        local tmpdir
        tmpdir=$(mktemp -d)
        echo ">>> NT=$nt, WIN=$win -> outputs = $(( last + 1 )) (i=0..$last)"

        for (( i=0; i<=last; i+=step )); do
        j=$(( i + win - 1 ))
        3dTstat -mean -prefix "${tmpdir}/m_${i}-${j}.nii.gz" "${out_psc}[${i}..${j}]"
        done

        echo ">>> Concatenating sliding-window means..."
        3dTcat -prefix "$out_sliding" "${tmpdir}"/m_*.nii.gz
        rm -rf "$tmpdir"

        echo ">>> Done."
        echo ">>> Outputs:"
        echo "    - baseline_image_${base_label}.nii.gz"
        echo "    - $out_psc"
        echo "    - $out_sliding"
        echo ">>> Check: sub-brick 0 = mean(0..$((win-1))), 1 = mean(1..$win), ..., $last = mean($last..$((nt-1)))"
}
