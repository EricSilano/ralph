#!/bin/bash
# ralph-lib.sh - Shared utility functions for Ralph automation system
# This library provides logging, metrics, and common utilities

# ==============================================================================
# Configuration Defaults
# ==============================================================================
RALPH_LOG_LEVEL="${RALPH_LOG_LEVEL:-INFO}"
RALPH_LOG_DIR="${RALPH_LOG_DIR:-logs}"
RALPH_LOG_COLORS="${RALPH_LOG_COLORS:-true}"

# ==============================================================================
# Log Level Definitions (compatible with bash 3.x)
# ==============================================================================
# Returns numeric value for log level (higher = more severe)
_ralph_level_to_num() {
    case "$1" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN)  echo 2 ;;
        ERROR) echo 3 ;;
        *)     echo 1 ;;  # Default to INFO
    esac
}

# ==============================================================================
# Color Definitions
# ==============================================================================
if [[ "$RALPH_LOG_COLORS" == "true" ]] && [[ -t 1 ]]; then
    COLOR_RESET="\033[0m"
    COLOR_DEBUG="\033[36m"    # Cyan
    COLOR_INFO="\033[32m"     # Green
    COLOR_WARN="\033[33m"     # Yellow
    COLOR_ERROR="\033[31m"    # Red
    COLOR_BOLD="\033[1m"
    COLOR_DIM="\033[2m"
else
    COLOR_RESET=""
    COLOR_DEBUG=""
    COLOR_INFO=""
    COLOR_WARN=""
    COLOR_ERROR=""
    COLOR_BOLD=""
    COLOR_DIM=""
fi

# ==============================================================================
# Timestamp Functions
# ==============================================================================

# Get current timestamp in ISO 8601 format
# Usage: timestamp=$(ralph_timestamp)
ralph_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Get current timestamp in ISO 8601 format with local timezone
# Usage: timestamp=$(ralph_timestamp_local)
ralph_timestamp_local() {
    date +"%Y-%m-%dT%H:%M:%S%z"
}

# Get current date in YYYY-MM-DD format
# Usage: date_str=$(ralph_date)
ralph_date() {
    date +"%Y-%m-%d"
}

# ==============================================================================
# Core Logging Functions
# ==============================================================================

# Internal function to check if a log level should be displayed
# Usage: _ralph_should_log "INFO"
_ralph_should_log() {
    local level="$1"
    local current_level_num
    local message_level_num
    current_level_num=$(_ralph_level_to_num "$RALPH_LOG_LEVEL")
    message_level_num=$(_ralph_level_to_num "$level")

    [[ "$message_level_num" -ge "$current_level_num" ]]
}

# Internal function to get color for log level
# Usage: color=$(_ralph_get_color "INFO")
_ralph_get_color() {
    local level="$1"
    case "$level" in
        DEBUG) echo "$COLOR_DEBUG" ;;
        INFO)  echo "$COLOR_INFO" ;;
        WARN)  echo "$COLOR_WARN" ;;
        ERROR) echo "$COLOR_ERROR" ;;
        *)     echo "$COLOR_RESET" ;;
    esac
}

# Core logging function
# Usage: ralph_log "INFO" "This is a message"
ralph_log() {
    local level="$1"
    local message="$2"

    if ! _ralph_should_log "$level"; then
        return 0
    fi

    local timestamp
    timestamp=$(ralph_timestamp_local)
    local color
    color=$(_ralph_get_color "$level")

    # Format: [TIMESTAMP] [LEVEL] message
    printf "%b[%s]%b %b[%-5s]%b %s\n" \
        "$COLOR_DIM" "$timestamp" "$COLOR_RESET" \
        "$color" "$level" "$COLOR_RESET" \
        "$message" >&2
}

# Convenience logging functions
# Usage: ralph_debug "Debug message"
ralph_debug() {
    ralph_log "DEBUG" "$1"
}

# Usage: ralph_info "Info message"
ralph_info() {
    ralph_log "INFO" "$1"
}

# Usage: ralph_warn "Warning message"
ralph_warn() {
    ralph_log "WARN" "$1"
}

# Usage: ralph_error "Error message"
ralph_error() {
    ralph_log "ERROR" "$1"
}

# ==============================================================================
# File Logging Functions
# ==============================================================================

# Ensure log directory exists and create required log files
# Usage: ralph_init_logs
ralph_init_logs() {
    if [[ ! -d "$RALPH_LOG_DIR" ]]; then
        mkdir -p "$RALPH_LOG_DIR"
        ralph_debug "Created log directory: $RALPH_LOG_DIR"
    fi
}

# Initialize the complete logging system with directory and files
# Usage: ralph_setup_logging
ralph_setup_logging() {
    ralph_init_logs

    local date_str
    date_str=$(ralph_date)
    local daily_log="${RALPH_LOG_DIR}/ralph-${date_str}.log"
    local errors_log="${RALPH_LOG_DIR}/ralph-errors.log"
    local metrics_log="${RALPH_LOG_DIR}/ralph-metrics.log"

    # Touch files to ensure they exist
    touch "$daily_log" "$errors_log" "$metrics_log"

    ralph_debug "Logging system initialized"
    ralph_debug "Daily log: $daily_log"
    ralph_debug "Errors log: $errors_log"
    ralph_debug "Metrics log: $metrics_log"
}

# Get the path to today's daily log file
# Usage: logfile=$(ralph_get_daily_log_path)
ralph_get_daily_log_path() {
    local date_str
    date_str=$(ralph_date)
    echo "${RALPH_LOG_DIR}/ralph-${date_str}.log"
}

# Get the path to the errors log file
# Usage: logfile=$(ralph_get_errors_log_path)
ralph_get_errors_log_path() {
    echo "${RALPH_LOG_DIR}/ralph-errors.log"
}

# Get the path to the metrics log file
# Usage: logfile=$(ralph_get_metrics_log_path)
ralph_get_metrics_log_path() {
    echo "${RALPH_LOG_DIR}/ralph-metrics.log"
}

# Rotate old log files (keeps last N days of daily logs)
# Usage: ralph_rotate_logs [days_to_keep]
ralph_rotate_logs() {
    local days_to_keep="${1:-30}"

    ralph_init_logs

    # Find and remove old daily log files
    local count=0
    while IFS= read -r -d '' logfile; do
        rm -f "$logfile"
        count=$((count + 1))
    done < <(find "$RALPH_LOG_DIR" -name "ralph-????-??-??.log" -type f -mtime +"$days_to_keep" -print0 2>/dev/null)

    if [[ $count -gt 0 ]]; then
        ralph_info "Rotated $count old log file(s) (older than $days_to_keep days)"
    fi
}

# Log message to file (always logs regardless of level)
# Usage: ralph_log_to_file "filename.log" "message"
ralph_log_to_file() {
    local filename="$1"
    local message="$2"
    local timestamp
    timestamp=$(ralph_timestamp_local)

    ralph_init_logs
    echo "[$timestamp] $message" >> "${RALPH_LOG_DIR}/${filename}"
}

# Log to daily rotating log file
# Usage: ralph_log_daily "INFO" "message"
ralph_log_daily() {
    local level="$1"
    local message="$2"
    local date_str
    date_str=$(ralph_date)
    local filename="ralph-${date_str}.log"

    ralph_log_to_file "$filename" "[$level] $message"
}

# Log error to dedicated error log
# Usage: ralph_log_error_file "Error message" "context info"
ralph_log_error_file() {
    local message="$1"
    local context="${2:-}"
    local timestamp
    timestamp=$(ralph_timestamp_local)

    ralph_init_logs
    {
        echo "================================================================================"
        echo "Timestamp: $timestamp"
        echo "Error: $message"
        if [[ -n "$context" ]]; then
            echo "Context: $context"
        fi
        echo ""
    } >> "${RALPH_LOG_DIR}/ralph-errors.log"
}

# ==============================================================================
# JSON Logging Functions (for metrics)
# ==============================================================================

# Escape a string for safe JSON inclusion
# Usage: escaped=$(ralph_json_escape "string with \"quotes\" and \\ backslashes")
ralph_json_escape() {
    local str="$1"
    # Escape backslashes first, then quotes, then control characters
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Build a JSON array from a comma-separated list
# Usage: json_array=$(ralph_json_array "file1.sh,file2.sh,file3.sh")
ralph_json_array() {
    local csv_list="$1"

    if [[ -z "$csv_list" ]]; then
        echo "[]"
        return
    fi

    local result="["
    local first=true
    local remaining="$csv_list"

    while [[ -n "$remaining" ]]; do
        local item
        # Extract item before first comma (or entire string if no comma)
        if [[ "$remaining" == *,* ]]; then
            item="${remaining%%,*}"
            remaining="${remaining#*,}"
        else
            item="$remaining"
            remaining=""
        fi

        # Trim leading/trailing whitespace
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"

        if [[ "$first" == "true" ]]; then
            first=false
        else
            result+=","
        fi
        local escaped
        escaped=$(ralph_json_escape "$item")
        result+="\"${escaped}\""
    done
    result+="]"
    echo "$result"
}

# Log a JSON object to the metrics log
# Usage: ralph_log_json '{"iteration": 1, "status": "success"}'
ralph_log_json() {
    local json_data="$1"

    ralph_init_logs
    echo "$json_data" >> "${RALPH_LOG_DIR}/ralph-metrics.log"
}

# Create a structured JSON log entry for an iteration
# Usage: ralph_log_iteration 1 "task_name" 120 "success" "file1.sh,file2.sh"
ralph_log_iteration() {
    local iter_num="$1"
    local task_name="$2"
    local duration_secs="$3"
    local iter_status="$4"
    local files_changed="${5:-}"
    local ts
    ts=$(ralph_timestamp)

    local escaped_task
    escaped_task=$(ralph_json_escape "$task_name")
    local files_array
    files_array=$(ralph_json_array "$files_changed")

    local json_entry
    printf -v json_entry '{"type":"iteration","timestamp":"%s","iteration":%s,"task":"%s","duration_seconds":%s,"status":"%s","files_changed":%s}' \
        "$ts" "$iter_num" "$escaped_task" "$duration_secs" "$iter_status" "$files_array"
    ralph_log_json "$json_entry"
}

# Log session start as structured JSON
# Usage: ralph_log_session_start "session_id" 50 "PRD.md"
ralph_log_session_start() {
    local session_id="$1"
    local total_iterations="$2"
    local prd_file="${3:-PRD.md}"
    local ts
    ts=$(ralph_timestamp)

    local escaped_prd
    escaped_prd=$(ralph_json_escape "$prd_file")

    local json_entry
    printf -v json_entry '{"type":"session_start","timestamp":"%s","session_id":"%s","total_iterations":%s,"prd_file":"%s"}' \
        "$ts" "$session_id" "$total_iterations" "$escaped_prd"
    ralph_log_json "$json_entry"
}

# Log session end as structured JSON
# Usage: ralph_log_session_end "session_id" 50 45 3600 "completed"
ralph_log_session_end() {
    local session_id="$1"
    local total_iterations="$2"
    local successful_iterations="$3"
    local total_duration_secs="$4"
    local session_status="${5:-completed}"
    local ts
    ts=$(ralph_timestamp)

    local success_rate=0
    if [[ "$total_iterations" -gt 0 ]]; then
        success_rate=$((successful_iterations * 100 / total_iterations))
    fi
    local failed_iterations=$((total_iterations - successful_iterations))

    local json_entry
    printf -v json_entry '{"type":"session_end","timestamp":"%s","session_id":"%s","total_iterations":%s,"successful_iterations":%s,"failed_iterations":%s,"total_duration_seconds":%s,"success_rate_percent":%s,"status":"%s"}' \
        "$ts" "$session_id" "$total_iterations" "$successful_iterations" "$failed_iterations" "$total_duration_secs" "$success_rate" "$session_status"
    ralph_log_json "$json_entry"
}

# Log an error as structured JSON
# Usage: ralph_log_error_json "Error message" "iteration" 5 "task_name"
ralph_log_error_json() {
    local error_message="$1"
    local error_context="${2:-unknown}"
    local iteration="${3:-0}"
    local task_name="${4:-}"
    local ts
    ts=$(ralph_timestamp)

    local escaped_message
    escaped_message=$(ralph_json_escape "$error_message")
    local escaped_task
    escaped_task=$(ralph_json_escape "$task_name")

    local json_entry
    printf -v json_entry '{"type":"error","timestamp":"%s","message":"%s","context":"%s","iteration":%s,"task":"%s"}' \
        "$ts" "$escaped_message" "$error_context" "$iteration" "$escaped_task"
    ralph_log_json "$json_entry"
}

# Generate a unique session ID
# Usage: session_id=$(ralph_generate_session_id)
ralph_generate_session_id() {
    local ts
    ts=$(date +"%Y%m%d%H%M%S")
    local random_suffix
    random_suffix=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
    echo "ralph-${ts}-${random_suffix}"
}

# ==============================================================================
# Status File Functions (Real-time Monitoring)
# ==============================================================================

# Default status file path
RALPH_STATUS_FILE="${RALPH_STATUS_FILE:-.ralph-status.json}"

# Write current status to the status file for real-time monitoring
# Usage: ralph_write_status "running" "session_id" 5 50 "task name"
ralph_write_status() {
    local run_status="$1"
    local session_id="$2"
    local current_iteration="${3:-0}"
    local total_iterations="${4:-0}"
    local current_task="${5:-}"
    local start_time="${6:-}"
    local ts
    ts=$(ralph_timestamp)

    local escaped_task
    escaped_task=$(ralph_json_escape "$current_task")

    local progress_percent=0
    if [[ "$total_iterations" -gt 0 ]] && [[ "$current_iteration" -gt 0 ]]; then
        progress_percent=$(( (current_iteration - 1) * 100 / total_iterations ))
    fi

    local json_status
    printf -v json_status '{"status":"%s","session_id":"%s","current_iteration":%s,"total_iterations":%s,"progress_percent":%s,"current_task":"%s","start_time":"%s","last_updated":"%s"}' \
        "$run_status" "$session_id" "$current_iteration" "$total_iterations" "$progress_percent" "$escaped_task" "$start_time" "$ts"

    echo "$json_status" > "$RALPH_STATUS_FILE"
}

# Update status to indicate iteration in progress
# Usage: ralph_status_iteration_start "session_id" 5 50 "task name" "start_time"
ralph_status_iteration_start() {
    local session_id="$1"
    local current_iteration="$2"
    local total_iterations="$3"
    local current_task="${4:-auto}"
    local start_time="${5:-}"
    ralph_write_status "running" "$session_id" "$current_iteration" "$total_iterations" "$current_task" "$start_time"
}

# Update status to indicate iteration completed
# Usage: ralph_status_iteration_complete "session_id" 5 50 "start_time"
ralph_status_iteration_complete() {
    local session_id="$1"
    local current_iteration="$2"
    local total_iterations="$3"
    local start_time="${4:-}"
    ralph_write_status "iteration_complete" "$session_id" "$current_iteration" "$total_iterations" "" "$start_time"
}

# Update status to indicate session completed
# Usage: ralph_status_session_complete "session_id" 50 50
ralph_status_session_complete() {
    local session_id="$1"
    local completed_iterations="$2"
    local total_iterations="$3"
    local ts
    ts=$(ralph_timestamp)

    local json_status
    printf -v json_status '{"status":"completed","session_id":"%s","current_iteration":%s,"total_iterations":%s,"progress_percent":100,"current_task":"","start_time":"","last_updated":"%s"}' \
        "$session_id" "$completed_iterations" "$total_iterations" "$ts"

    echo "$json_status" > "$RALPH_STATUS_FILE"
}

# Update status to indicate session idle/stopped
# Usage: ralph_status_idle
ralph_status_idle() {
    local ts
    ts=$(ralph_timestamp)

    local json_status
    printf -v json_status '{"status":"idle","session_id":"","current_iteration":0,"total_iterations":0,"progress_percent":0,"current_task":"","start_time":"","last_updated":"%s"}' "$ts"

    echo "$json_status" > "$RALPH_STATUS_FILE"
}

# Read current status from status file
# Usage: status=$(ralph_read_status)
ralph_read_status() {
    if [[ -f "$RALPH_STATUS_FILE" ]]; then
        cat "$RALPH_STATUS_FILE"
    else
        echo '{"status":"unknown","session_id":"","current_iteration":0,"total_iterations":0,"progress_percent":0,"current_task":"","start_time":"","last_updated":""}'
    fi
}

# Remove status file (cleanup)
# Usage: ralph_clear_status
ralph_clear_status() {
    if [[ -f "$RALPH_STATUS_FILE" ]]; then
        rm -f "$RALPH_STATUS_FILE"
    fi
}

# ==============================================================================
# Summary Report Functions
# ==============================================================================

# Default summary file path
RALPH_SUMMARY_FILE="${RALPH_SUMMARY_FILE:-ralph-summary.txt}"

# Generate a summary report at the end of a session
# Usage: ralph_generate_summary "session_id" 50 45 5 3600 "completed" "file1.sh,file2.sh"
ralph_generate_summary() {
    local session_id="$1"
    local total_iterations="$2"
    local successful_iterations="$3"
    local failed_iterations="$4"
    local total_duration_secs="$5"
    local session_status="$6"
    local files_modified="${7:-}"
    local ts
    ts=$(ralph_timestamp_local)

    local formatted_duration
    formatted_duration=$(ralph_format_duration "$total_duration_secs")

    local success_rate=0
    if [[ "$total_iterations" -gt 0 ]]; then
        success_rate=$((successful_iterations * 100 / total_iterations))
    fi

    local avg_time=0
    local avg_formatted="N/A"
    if [[ "$successful_iterations" -gt 0 ]]; then
        avg_time=$((total_duration_secs / successful_iterations))
        avg_formatted=$(ralph_format_duration "$avg_time")
    fi

    # Write the summary report
    {
        echo "================================================================================"
        echo "                         RALPH SESSION SUMMARY REPORT"
        echo "================================================================================"
        echo ""
        echo "Session ID:        $session_id"
        echo "Generated:         $ts"
        echo "Status:            $session_status"
        echo ""
        echo "--------------------------------------------------------------------------------"
        echo "                              ITERATION METRICS"
        echo "--------------------------------------------------------------------------------"
        echo ""
        echo "Total Iterations:       $total_iterations"
        echo "Successful:             $successful_iterations"
        echo "Failed:                 $failed_iterations"
        echo "Success Rate:           ${success_rate}%"
        echo ""
        echo "--------------------------------------------------------------------------------"
        echo "                               TIME METRICS"
        echo "--------------------------------------------------------------------------------"
        echo ""
        echo "Total Duration:         $formatted_duration"
        echo "Average per Iteration:  $avg_formatted"
        echo ""
        echo "--------------------------------------------------------------------------------"
        echo "                            FILES MODIFIED"
        echo "--------------------------------------------------------------------------------"
        echo ""
        if [[ -n "$files_modified" ]]; then
            # Split comma-separated files and list them
            local remaining="$files_modified"
            local file_count=0
            while [[ -n "$remaining" ]]; do
                local item
                if [[ "$remaining" == *,* ]]; then
                    item="${remaining%%,*}"
                    remaining="${remaining#*,}"
                else
                    item="$remaining"
                    remaining=""
                fi
                # Trim whitespace
                item="${item#"${item%%[![:space:]]*}"}"
                item="${item%"${item##*[![:space:]]}"}"
                if [[ -n "$item" ]]; then
                    echo "  - $item"
                    file_count=$((file_count + 1))
                fi
            done
            echo ""
            echo "Total files modified: $file_count"
        else
            echo "  (No files tracked - use git diff to see changes)"
        fi
        echo ""
        echo "================================================================================"
        echo "                              END OF REPORT"
        echo "================================================================================"
    } > "$RALPH_SUMMARY_FILE"

    ralph_info "Summary report generated: $RALPH_SUMMARY_FILE"
}

# Get list of modified files from git (if in a git repo)
# Usage: modified_files=$(ralph_get_git_modified_files)
ralph_get_git_modified_files() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Get modified, added, and deleted files
        git diff --name-only HEAD 2>/dev/null | tr '\n' ',' | sed 's/,$//'
    else
        echo ""
    fi
}

# Get list of modified files since a given timestamp (from git log)
# Usage: modified_files=$(ralph_get_files_modified_since "2026-01-14T10:00:00Z")
ralph_get_files_modified_since() {
    local since_time="$1"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git diff --name-only --since="$since_time" HEAD 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//'
    else
        echo ""
    fi
}

# ==============================================================================
# Code Validation Functions
# ==============================================================================

# Default validation log file path
RALPH_VALIDATION_LOG="${RALPH_VALIDATION_LOG:-${RALPH_LOG_DIR}/ralph-validation.log}"

# Get the path to the validation log file
# Usage: logfile=$(ralph_get_validation_log_path)
ralph_get_validation_log_path() {
    echo "${RALPH_LOG_DIR}/ralph-validation.log"
}

# Log a validation result entry
# Usage: ralph_log_validation "shellcheck" "ralph-lib.sh" "pass" ""
ralph_log_validation() {
    local tool="$1"
    local file="$2"
    local result="$3"
    local details="${4:-}"
    local ts
    ts=$(ralph_timestamp_local)

    ralph_init_logs
    {
        echo "[$ts] [$tool] $file: $result"
        if [[ -n "$details" ]]; then
            echo "$details" | sed 's/^/    /'
        fi
    } >> "$(ralph_get_validation_log_path)"
}

# Log validation summary as JSON to metrics log
# Usage: ralph_log_validation_json "iteration" 5 3 2 0
ralph_log_validation_json() {
    local context="$1"
    local iteration="$2"
    local total_files="$3"
    local passed="$4"
    local warnings="$5"
    local ts
    ts=$(ralph_timestamp)

    local json_entry
    printf -v json_entry '{"type":"validation","timestamp":"%s","context":"%s","iteration":%s,"total_files":%s,"passed":%s,"warnings":%s}' \
        "$ts" "$context" "$iteration" "$total_files" "$passed" "$warnings"
    ralph_log_json "$json_entry"
}

# Run shellcheck on a single bash file
# Usage: result=$(ralph_shellcheck_file "script.sh")
# Returns: "pass", "warn", or "skip"
ralph_shellcheck_file() {
    local file="$1"
    local output

    # Check if shellcheck is available
    if ! command -v shellcheck &> /dev/null; then
        ralph_debug "shellcheck not installed, skipping validation for $file"
        echo "skip"
        return 0
    fi

    # Run shellcheck and capture output
    output=$(shellcheck -f gcc "$file" 2>&1) || true

    if [[ -z "$output" ]]; then
        ralph_log_validation "shellcheck" "$file" "PASS" ""
        echo "pass"
    else
        ralph_log_validation "shellcheck" "$file" "WARN" "$output"
        echo "warn"
    fi
}

# Run eslint on a single JavaScript/TypeScript file
# Usage: result=$(ralph_eslint_file "script.js")
# Returns: "pass", "warn", or "skip"
ralph_eslint_file() {
    local file="$1"
    local output

    # Check if eslint is available (local or global)
    local eslint_cmd=""
    if [[ -x "./node_modules/.bin/eslint" ]]; then
        eslint_cmd="./node_modules/.bin/eslint"
    elif command -v eslint &> /dev/null; then
        eslint_cmd="eslint"
    else
        ralph_debug "eslint not found, skipping validation for $file"
        echo "skip"
        return 0
    fi

    # Run eslint and capture output
    output=$("$eslint_cmd" --format compact "$file" 2>&1) || true

    if [[ -z "$output" ]] || [[ "$output" == *"0 problems"* ]]; then
        ralph_log_validation "eslint" "$file" "PASS" ""
        echo "pass"
    else
        ralph_log_validation "eslint" "$file" "WARN" "$output"
        echo "warn"
    fi
}

# Run prettier check on a single file
# Usage: result=$(ralph_prettier_file "script.js")
# Returns: "pass", "warn", or "skip"
ralph_prettier_file() {
    local file="$1"
    local output

    # Check if prettier is available (local or global)
    local prettier_cmd=""
    if [[ -x "./node_modules/.bin/prettier" ]]; then
        prettier_cmd="./node_modules/.bin/prettier"
    elif command -v prettier &> /dev/null; then
        prettier_cmd="prettier"
    else
        ralph_debug "prettier not found, skipping validation for $file"
        echo "skip"
        return 0
    fi

    # Run prettier check (--check returns non-zero if formatting needed)
    if "$prettier_cmd" --check "$file" &> /dev/null; then
        ralph_log_validation "prettier" "$file" "PASS" ""
        echo "pass"
    else
        ralph_log_validation "prettier" "$file" "WARN" "File needs formatting"
        echo "warn"
    fi
}

# Validate all modified bash files using shellcheck
# Usage: ralph_validate_bash_files "file1.sh,file2.sh"
# Returns: number of warnings found
ralph_validate_bash_files() {
    local files_csv="$1"
    local warnings=0
    local checked=0
    local skipped=0

    if [[ -z "$files_csv" ]]; then
        echo "0"
        return 0
    fi

    # Check if shellcheck is available before iterating
    if ! command -v shellcheck &> /dev/null; then
        ralph_warn "shellcheck not installed, skipping bash file validation"
        echo "0"
        return 0
    fi

    local remaining="$files_csv"
    while [[ -n "$remaining" ]]; do
        local file
        if [[ "$remaining" == *,* ]]; then
            file="${remaining%%,*}"
            remaining="${remaining#*,}"
        else
            file="$remaining"
            remaining=""
        fi

        # Trim whitespace
        file="${file#"${file%%[![:space:]]*}"}"
        file="${file%"${file##*[![:space:]]}"}"

        # Check if it's a bash file
        if [[ "$file" == *.sh ]] && [[ -f "$file" ]]; then
            checked=$((checked + 1))
            local result
            result=$(ralph_shellcheck_file "$file")
            if [[ "$result" == "warn" ]]; then
                warnings=$((warnings + 1))
            elif [[ "$result" == "skip" ]]; then
                skipped=$((skipped + 1))
            fi
        fi
    done

    if [[ $checked -gt 0 ]]; then
        ralph_debug "Validated $checked bash file(s), $warnings warning(s), $skipped skipped"
    fi
    echo "$warnings"
}

# Validate all modified JavaScript/TypeScript files
# Usage: ralph_validate_js_files "file1.js,file2.ts"
# Returns: number of warnings found
ralph_validate_js_files() {
    local files_csv="$1"
    local warnings=0
    local checked=0

    if [[ -z "$files_csv" ]]; then
        echo "0"
        return 0
    fi

    # Check if eslint or prettier is available
    local has_eslint=false
    local has_prettier=false
    if [[ -x "./node_modules/.bin/eslint" ]] || command -v eslint &> /dev/null; then
        has_eslint=true
    fi
    if [[ -x "./node_modules/.bin/prettier" ]] || command -v prettier &> /dev/null; then
        has_prettier=true
    fi

    if [[ "$has_eslint" == "false" ]] && [[ "$has_prettier" == "false" ]]; then
        ralph_warn "Neither eslint nor prettier installed, skipping JS/TS validation"
        echo "0"
        return 0
    fi

    local remaining="$files_csv"
    while [[ -n "$remaining" ]]; do
        local file
        if [[ "$remaining" == *,* ]]; then
            file="${remaining%%,*}"
            remaining="${remaining#*,}"
        else
            file="$remaining"
            remaining=""
        fi

        # Trim whitespace
        file="${file#"${file%%[![:space:]]*}"}"
        file="${file%"${file##*[![:space:]]}"}"

        # Check if it's a JS/TS file
        if [[ "$file" == *.js ]] || [[ "$file" == *.ts ]] || [[ "$file" == *.jsx ]] || [[ "$file" == *.tsx ]]; then
            if [[ -f "$file" ]]; then
                checked=$((checked + 1))
                local eslint_result prettier_result
                eslint_result=$(ralph_eslint_file "$file")
                prettier_result=$(ralph_prettier_file "$file")
                if [[ "$eslint_result" == "warn" ]] || [[ "$prettier_result" == "warn" ]]; then
                    warnings=$((warnings + 1))
                fi
            fi
        fi
    done

    if [[ $checked -gt 0 ]]; then
        ralph_debug "Validated $checked JS/TS file(s), $warnings warning(s)"
    fi
    echo "$warnings"
}

# Run all code validations on modified files after an iteration
# Usage: ralph_run_validation 5 "file1.sh,file2.js,file3.ts"
# Logs results and returns total warnings (does not fail the iteration)
ralph_run_validation() {
    local iteration="$1"
    local files_csv="$2"
    local total_warnings=0
    local total_files=0
    local bash_warnings=0
    local js_warnings=0
    local ts
    ts=$(ralph_timestamp_local)

    if [[ -z "$files_csv" ]]; then
        ralph_debug "No files to validate for iteration $iteration"
        return 0
    fi

    ralph_init_logs

    # Log validation start
    {
        echo ""
        echo "================================================================================"
        echo "[$ts] Validation for iteration $iteration"
        echo "================================================================================"
    } >> "$(ralph_get_validation_log_path)"

    # Count files by type
    local remaining="$files_csv"
    local bash_count=0
    local js_count=0
    while [[ -n "$remaining" ]]; do
        local file
        if [[ "$remaining" == *,* ]]; then
            file="${remaining%%,*}"
            remaining="${remaining#*,}"
        else
            file="$remaining"
            remaining=""
        fi
        file="${file#"${file%%[![:space:]]*}"}"
        file="${file%"${file##*[![:space:]]}"}"

        if [[ "$file" == *.sh ]]; then
            bash_count=$((bash_count + 1))
        elif [[ "$file" == *.js ]] || [[ "$file" == *.ts ]] || [[ "$file" == *.jsx ]] || [[ "$file" == *.tsx ]]; then
            js_count=$((js_count + 1))
        fi
    done

    total_files=$((bash_count + js_count))

    # Validate bash files
    if [[ $bash_count -gt 0 ]]; then
        ralph_info "Validating $bash_count bash file(s) with shellcheck..."
        bash_warnings=$(ralph_validate_bash_files "$files_csv")
        total_warnings=$((total_warnings + bash_warnings))
    fi

    # Validate JS/TS files
    if [[ $js_count -gt 0 ]]; then
        ralph_info "Validating $js_count JS/TS file(s) with eslint/prettier..."
        js_warnings=$(ralph_validate_js_files "$files_csv")
        total_warnings=$((total_warnings + js_warnings))
    fi

    # Log summary
    local passed_files=$((total_files - total_warnings))
    ralph_log_validation_json "iteration" "$iteration" "$total_files" "$passed_files" "$total_warnings"

    if [[ $total_warnings -gt 0 ]]; then
        ralph_warn "Validation completed: $total_warnings warning(s) in $total_files file(s)"
        ralph_warn "See $(ralph_get_validation_log_path) for details"
    else
        if [[ $total_files -gt 0 ]]; then
            ralph_info "Validation passed: all $total_files file(s) clean"
        fi
    fi

    echo "$total_warnings"
}

# ==============================================================================
# Retry Configuration and Functions
# ==============================================================================

# Default retry configuration
RALPH_MAX_RETRIES="${RALPH_MAX_RETRIES:-3}"
RALPH_RETRY_BASE_DELAY="${RALPH_RETRY_BASE_DELAY:-5}"  # Base delay in seconds

# Calculate exponential backoff delay
# Usage: delay=$(ralph_get_backoff_delay 2)  # Returns delay for retry attempt 2
# Formula: base_delay * (2 ^ attempt) with some randomization
ralph_get_backoff_delay() {
    local attempt="$1"
    local base_delay="${RALPH_RETRY_BASE_DELAY:-5}"

    # Calculate 2^attempt using bash arithmetic
    local multiplier=1
    local i
    for ((i=0; i<attempt; i++)); do
        multiplier=$((multiplier * 2))
    done

    local delay=$((base_delay * multiplier))

    # Add some jitter (0-25% of delay) to prevent thundering herd
    local jitter=$((delay / 4))
    if [[ $jitter -gt 0 ]]; then
        # Use $RANDOM for jitter (bash built-in)
        jitter=$((RANDOM % jitter))
    fi

    echo $((delay + jitter))
}

# Log a retry attempt
# Usage: ralph_log_retry 5 2 3 "exit code 1" 10
ralph_log_retry() {
    local iteration="$1"
    local attempt="$2"
    local max_retries="$3"
    local reason="$4"
    local delay="$5"
    local ts
    ts=$(ralph_timestamp)

    local escaped_reason
    escaped_reason=$(ralph_json_escape "$reason")

    # Log to daily log
    ralph_log_daily "WARN" "Iteration $iteration: Retry attempt $attempt/$max_retries after failure ($reason), waiting ${delay}s"

    # Log to error file with context
    ralph_log_error_file \
        "Retry scheduled for iteration $iteration" \
        "Attempt: $attempt/$max_retries, Reason: $reason, Backoff delay: ${delay}s"

    # Log as JSON to metrics
    local json_entry
    printf -v json_entry '{"type":"retry","timestamp":"%s","iteration":%s,"attempt":%s,"max_retries":%s,"reason":"%s","backoff_seconds":%s}' \
        "$ts" "$iteration" "$attempt" "$max_retries" "$escaped_reason" "$delay"
    ralph_log_json "$json_entry"
}

# Log when all retries are exhausted
# Usage: ralph_log_retry_exhausted 5 3 "exit code 1"
ralph_log_retry_exhausted() {
    local iteration="$1"
    local max_retries="$2"
    local reason="$3"
    local ts
    ts=$(ralph_timestamp)

    local escaped_reason
    escaped_reason=$(ralph_json_escape "$reason")

    # Log to daily log
    ralph_log_daily "ERROR" "Iteration $iteration: All $max_retries retry attempts exhausted ($reason)"

    # Log to error file
    ralph_log_error_file \
        "All retries exhausted for iteration $iteration" \
        "Max retries: $max_retries, Final failure reason: $reason"

    # Log as JSON
    local json_entry
    printf -v json_entry '{"type":"retry_exhausted","timestamp":"%s","iteration":%s,"max_retries":%s,"reason":"%s"}' \
        "$ts" "$iteration" "$max_retries" "$escaped_reason"
    ralph_log_json "$json_entry"
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Print a separator line
# Usage: ralph_separator
ralph_separator() {
    local char="${1:--}"
    local width="${2:-80}"
    printf '%*s\n' "$width" '' | tr ' ' "$char" >&2
}

# Print a header with separators
# Usage: ralph_header "Section Title"
ralph_header() {
    local title="$1"
    ralph_separator "="
    printf "%b%s%b\n" "$COLOR_BOLD" "$title" "$COLOR_RESET" >&2
    ralph_separator "="
}

# Format duration in human readable format
# Usage: formatted=$(ralph_format_duration 3665)
ralph_format_duration() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" "$hours" "$minutes" "$secs"
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" "$minutes" "$secs"
    else
        printf "%ds" "$secs"
    fi
}

# ==============================================================================
# Export functions for use in sourcing scripts
# ==============================================================================
export -f ralph_timestamp
export -f ralph_timestamp_local
export -f ralph_date
export -f ralph_log
export -f ralph_debug
export -f ralph_info
export -f ralph_warn
export -f ralph_error
export -f ralph_init_logs
export -f ralph_setup_logging
export -f ralph_get_daily_log_path
export -f ralph_get_errors_log_path
export -f ralph_get_metrics_log_path
export -f ralph_rotate_logs
export -f ralph_log_to_file
export -f ralph_log_daily
export -f ralph_log_error_file
export -f ralph_json_escape
export -f ralph_json_array
export -f ralph_log_json
export -f ralph_log_iteration
export -f ralph_log_session_start
export -f ralph_log_session_end
export -f ralph_log_error_json
export -f ralph_generate_session_id
export -f ralph_separator
export -f ralph_header
export -f ralph_format_duration
export -f ralph_write_status
export -f ralph_status_iteration_start
export -f ralph_status_iteration_complete
export -f ralph_status_session_complete
export -f ralph_status_idle
export -f ralph_read_status
export -f ralph_clear_status
export -f ralph_generate_summary
export -f ralph_get_git_modified_files
export -f ralph_get_files_modified_since
export -f ralph_get_validation_log_path
export -f ralph_log_validation
export -f ralph_log_validation_json
export -f ralph_shellcheck_file
export -f ralph_eslint_file
export -f ralph_prettier_file
export -f ralph_validate_bash_files
export -f ralph_validate_js_files
export -f ralph_run_validation
export -f ralph_get_backoff_delay
export -f ralph_log_retry
export -f ralph_log_retry_exhausted

# ==============================================================================
# State Persistence Functions (for pause/resume and graceful shutdown)
# ==============================================================================

# Default state file path
RALPH_STATE_FILE="${RALPH_STATE_FILE:-.ralph-state.json}"

# Save current session state to state file
# Usage: ralph_save_state "session_id" 5 50 "completed_iters" "failed_iters" "total_time" "start_time"
ralph_save_state() {
    local session_id="$1"
    local current_iteration="$2"
    local total_iterations="$3"
    local completed_iterations="${4:-0}"
    local failed_iterations="${5:-0}"
    local total_iteration_time="${6:-0}"
    local session_start_time="${7:-}"
    local session_status="${8:-interrupted}"
    local ts
    ts=$(ralph_timestamp)

    local json_state
    printf -v json_state '{"session_id":"%s","current_iteration":%s,"total_iterations":%s,"completed_iterations":%s,"failed_iterations":%s,"total_iteration_time":%s,"session_start_time":"%s","status":"%s","saved_at":"%s"}' \
        "$session_id" "$current_iteration" "$total_iterations" "$completed_iterations" "$failed_iterations" "$total_iteration_time" "$session_start_time" "$session_status" "$ts"

    echo "$json_state" > "$RALPH_STATE_FILE"
}

# Read saved state from state file
# Usage: state_json=$(ralph_read_state)
ralph_read_state() {
    if [[ -f "$RALPH_STATE_FILE" ]]; then
        cat "$RALPH_STATE_FILE"
    else
        echo ""
    fi
}

# Check if a saved state exists and is resumable
# Usage: if ralph_has_resumable_state; then ...
ralph_has_resumable_state() {
    if [[ -f "$RALPH_STATE_FILE" ]]; then
        local state_status
        state_status=$(ralph_get_state_field "status")
        [[ "$state_status" == "interrupted" ]]
    else
        return 1
    fi
}

# Get a specific field from the state file using basic string parsing
# Usage: session_id=$(ralph_get_state_field "session_id")
ralph_get_state_field() {
    local field="$1"
    if [[ -f "$RALPH_STATE_FILE" ]]; then
        local content
        content=$(cat "$RALPH_STATE_FILE")
        # Extract value using pattern matching
        # Handles both string and numeric values
        case "$field" in
            session_id|status|session_start_time|saved_at)
                # String field - extract between quotes
                echo "$content" | sed -n "s/.*\"${field}\":\"\([^\"]*\)\".*/\1/p"
                ;;
            *)
                # Numeric field - extract number
                echo "$content" | sed -n "s/.*\"${field}\":\([0-9]*\).*/\1/p"
                ;;
        esac
    else
        echo ""
    fi
}

# Clear state file (used after successful completion or manual clear)
# Usage: ralph_clear_state
ralph_clear_state() {
    if [[ -f "$RALPH_STATE_FILE" ]]; then
        rm -f "$RALPH_STATE_FILE"
    fi
}

# Update status file to show interrupted state
# Usage: ralph_status_interrupted "session_id" 5 50 "start_time"
ralph_status_interrupted() {
    local session_id="$1"
    local current_iteration="$2"
    local total_iterations="$3"
    local start_time="${4:-}"
    local ts
    ts=$(ralph_timestamp)

    local progress_percent=0
    if [[ "$total_iterations" -gt 0 ]] && [[ "$current_iteration" -gt 0 ]]; then
        progress_percent=$(( (current_iteration - 1) * 100 / total_iterations ))
    fi

    local json_status
    printf -v json_status '{"status":"interrupted","session_id":"%s","current_iteration":%s,"total_iterations":%s,"progress_percent":%s,"current_task":"","start_time":"%s","last_updated":"%s"}' \
        "$session_id" "$current_iteration" "$total_iterations" "$progress_percent" "$start_time" "$ts"

    echo "$json_status" > "$RALPH_STATUS_FILE"
}

# Log session interruption as JSON
# Usage: ralph_log_session_interrupted "session_id" 5 3 120 "SIGINT"
ralph_log_session_interrupted() {
    local session_id="$1"
    local total_iterations="$2"
    local completed_iterations="$3"
    local total_duration_secs="$4"
    local signal="${5:-unknown}"
    local ts
    ts=$(ralph_timestamp)

    local escaped_signal
    escaped_signal=$(ralph_json_escape "$signal")

    local json_entry
    printf -v json_entry '{"type":"session_interrupted","timestamp":"%s","session_id":"%s","total_iterations":%s,"completed_iterations":%s,"total_duration_seconds":%s,"signal":"%s"}' \
        "$ts" "$session_id" "$total_iterations" "$completed_iterations" "$total_duration_secs" "$escaped_signal"
    ralph_log_json "$json_entry"
}

# Export state functions
export -f ralph_save_state
export -f ralph_read_state
export -f ralph_has_resumable_state
export -f ralph_get_state_field
export -f ralph_clear_state
export -f ralph_status_interrupted
export -f ralph_log_session_interrupted

# ==============================================================================
# Context Summarization Functions
# ==============================================================================

# Default configuration for context summarization
RALPH_PROGRESS_FILE="${RALPH_PROGRESS_FILE:-progress.txt}"
RALPH_PROGRESS_ARCHIVE="${RALPH_PROGRESS_ARCHIVE:-progress-archive.txt}"
RALPH_PROGRESS_MAX_LINES="${RALPH_PROGRESS_MAX_LINES:-500}"
RALPH_PROGRESS_KEEP_LINES="${RALPH_PROGRESS_KEEP_LINES:-100}"

# Get the current line count of a file
# Usage: count=$(ralph_get_line_count "progress.txt")
ralph_get_line_count() {
    local file="$1"
    if [[ -f "$file" ]]; then
        wc -l < "$file" | tr -d ' '
    else
        echo "0"
    fi
}

# Extract task completion entries from progress content
# Usage: tasks=$(ralph_extract_completed_tasks "content")
ralph_extract_completed_tasks() {
    local content="$1"
    local tasks=""
    local in_task=false
    local current_date=""
    local current_task=""

    # Parse line by line using a while loop
    while IFS= read -r line; do
        # Check for date/task header (## YYYY-MM-DD: Task X.X - Description)
        # Using grep for more portable regex matching
        if echo "$line" | grep -qE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}: Task [^ ]+ - .+$'; then
            # Save previous task if exists
            if [[ -n "$current_task" ]]; then
                if [[ -n "$tasks" ]]; then
                    tasks="${tasks}\n"
                fi
                tasks="${tasks}${current_task}"
            fi
            # Extract fields using parameter expansion and sed
            current_date=$(echo "$line" | sed 's/^## \([0-9-]*\):.*/\1/')
            local task_num
            task_num=$(echo "$line" | sed 's/^## [0-9-]*: Task \([^ ]*\) -.*/\1/')
            local task_desc
            task_desc=$(echo "$line" | sed 's/^## [0-9-]*: Task [^ ]* - //')
            current_task="- [${current_date}] Task ${task_num}: ${task_desc}"
            in_task=true
        # Check for **Completed:** marker to confirm task was done
        elif [[ "$in_task" == "true" ]] && echo "$line" | grep -qE '^\*\*Completed:\*\* .+$'; then
            local completed_desc
            completed_desc=$(echo "$line" | sed 's/^\*\*Completed:\*\* //')
            current_task="${current_task} - ${completed_desc}"
        fi
    done <<< "$content"

    # Add last task
    if [[ -n "$current_task" ]]; then
        if [[ -n "$tasks" ]]; then
            tasks="${tasks}\n"
        fi
        tasks="${tasks}${current_task}"
    fi

    echo -e "$tasks"
}

# Generate a summary of older progress entries
# Usage: summary=$(ralph_generate_progress_summary "content")
ralph_generate_progress_summary() {
    local content="$1"
    local ts
    ts=$(ralph_timestamp_local)

    # Count tasks by extracting headers using grep for portability
    local task_count
    task_count=$(echo "$content" | grep -cE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}: Task ' || echo "0")

    # Extract task summaries
    local task_list
    task_list=$(ralph_extract_completed_tasks "$content")

    # Build summary
    local summary
    summary="## Progress Summary (Auto-generated: ${ts})

This is an auto-generated summary of ${task_count} completed task(s).
Full history has been archived to: ${RALPH_PROGRESS_ARCHIVE}

### Completed Tasks:
${task_list}

---
(End of summary - Recent progress entries follow below)

"
    echo "$summary"
}

# Archive older progress entries and summarize them
# Usage: ralph_summarize_progress ["progress.txt"]
# Returns: 0 if summarized, 1 if not needed, 2 on error
ralph_summarize_progress() {
    local progress_file="${1:-$RALPH_PROGRESS_FILE}"
    local archive_file="${RALPH_PROGRESS_ARCHIVE}"
    local max_lines="${RALPH_PROGRESS_MAX_LINES}"
    local keep_lines="${RALPH_PROGRESS_KEEP_LINES}"

    # Check if file exists
    if [[ ! -f "$progress_file" ]]; then
        ralph_debug "Progress file does not exist: $progress_file"
        return 1
    fi

    # Get current line count
    local line_count
    line_count=$(ralph_get_line_count "$progress_file")

    ralph_debug "Progress file has $line_count lines (max: $max_lines)"

    # Check if summarization is needed
    if [[ "$line_count" -le "$max_lines" ]]; then
        ralph_debug "Progress file under threshold, no summarization needed"
        return 1
    fi

    ralph_info "Progress file exceeds $max_lines lines ($line_count), summarizing..."

    # Calculate lines to archive (all except the last keep_lines)
    local archive_lines=$((line_count - keep_lines))

    # Read the entire file content
    local full_content
    full_content=$(cat "$progress_file")

    # Split content into old (to archive) and recent (to keep)
    local old_content
    local recent_content
    old_content=$(head -n "$archive_lines" "$progress_file")
    recent_content=$(tail -n "$keep_lines" "$progress_file")

    # Archive the old content
    local archive_ts
    archive_ts=$(ralph_timestamp_local)
    {
        echo ""
        echo "================================================================================"
        echo "ARCHIVED: ${archive_ts}"
        echo "Lines archived: ${archive_lines}"
        echo "================================================================================"
        echo ""
        echo "$old_content"
    } >> "$archive_file"

    ralph_log_daily "INFO" "Archived $archive_lines lines from progress.txt to $archive_file"

    # Generate summary of old content
    local summary
    summary=$(ralph_generate_progress_summary "$old_content")

    # Write summary + recent content back to progress file
    {
        echo "$summary"
        echo "$recent_content"
    } > "$progress_file"

    local new_line_count
    new_line_count=$(ralph_get_line_count "$progress_file")

    ralph_info "Summarized progress.txt: $line_count -> $new_line_count lines"
    ralph_log_daily "INFO" "Summarized progress.txt: $line_count -> $new_line_count lines (archived: $archive_lines)"

    # Log as JSON
    local json_entry
    json_entry=$(printf '{"type":"context_summarization","timestamp":"%s","original_lines":%s,"archived_lines":%s,"new_lines":%s,"archive_file":"%s"}' \
        "$(ralph_timestamp)" "$line_count" "$archive_lines" "$new_line_count" "$archive_file")
    ralph_log_json "$json_entry"

    return 0
}

# Check if progress file needs summarization (without doing it)
# Usage: if ralph_needs_summarization; then ...
ralph_needs_summarization() {
    local progress_file="${1:-$RALPH_PROGRESS_FILE}"
    local max_lines="${RALPH_PROGRESS_MAX_LINES}"

    if [[ ! -f "$progress_file" ]]; then
        return 1
    fi

    local line_count
    line_count=$(ralph_get_line_count "$progress_file")

    [[ "$line_count" -gt "$max_lines" ]]
}

# Export context summarization functions
export -f ralph_get_line_count
export -f ralph_extract_completed_tasks
export -f ralph_generate_progress_summary
export -f ralph_summarize_progress
export -f ralph_needs_summarization

# ==============================================================================
# Output Filtering Functions
# ==============================================================================

# Default configuration for output filtering
RALPH_FULL_OUTPUT_LOG="${RALPH_FULL_OUTPUT_LOG:-${RALPH_LOG_DIR}/ralph-full-output.log}"
RALPH_FILTER_OUTPUT="${RALPH_FILTER_OUTPUT:-true}"

# Get the path to the full output log file
# Usage: logfile=$(ralph_get_full_output_log_path)
ralph_get_full_output_log_path() {
    echo "${RALPH_LOG_DIR}/ralph-full-output.log"
}

# Log full Claude output to file
# Usage: ralph_log_full_output "session_id" 5 "full output content"
ralph_log_full_output() {
    local session_id="$1"
    local iteration="$2"
    local output="$3"
    local ts
    ts=$(ralph_timestamp_local)

    ralph_init_logs

    {
        echo ""
        echo "================================================================================"
        echo "Session: $session_id | Iteration: $iteration | Timestamp: $ts"
        echo "================================================================================"
        echo ""
        echo "$output"
        echo ""
    } >> "$(ralph_get_full_output_log_path)"
}

# Extract key information from Claude output for concise display
# Usage: summary=$(ralph_extract_output_summary "full output")
# Returns: A concise summary of key actions taken
ralph_extract_output_summary() {
    local output="$1"
    local summary=""
    local line_count=0
    local max_summary_lines=15

    # Check for PRD COMPLETE signal
    if echo "$output" | grep -q '<promise>COMPLETE</promise>'; then
        summary="✓ PRD marked as COMPLETE"
        echo "$summary"
        return 0
    fi

    # Extract files created/modified (look for common patterns)
    local files_created=""
    local files_modified=""
    local tests_run=""
    local errors_found=""

    # Look for file operation patterns in output
    # Pattern: "Created file:" or "Writing to:" or similar
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Check for file creation patterns
        if echo "$line" | grep -qiE '(created|wrote|writing|new file|added file|creating).*\.(sh|js|ts|py|md|json|yaml|yml|txt)'; then
            local file_match
            file_match=$(echo "$line" | grep -oE '[a-zA-Z0-9_/-]+\.(sh|js|ts|py|md|json|yaml|yml|txt)' | head -1)
            if [[ -n "$file_match" ]] && [[ ! "$files_created" == *"$file_match"* ]]; then
                if [[ -n "$files_created" ]]; then
                    files_created="${files_created}, ${file_match}"
                else
                    files_created="$file_match"
                fi
            fi
        fi

        # Check for file modification patterns
        if echo "$line" | grep -qiE '(modified|updated|edited|changed|editing).*\.(sh|js|ts|py|md|json|yaml|yml|txt)'; then
            local file_match
            file_match=$(echo "$line" | grep -oE '[a-zA-Z0-9_/-]+\.(sh|js|ts|py|md|json|yaml|yml|txt)' | head -1)
            if [[ -n "$file_match" ]] && [[ ! "$files_modified" == *"$file_match"* ]]; then
                if [[ -n "$files_modified" ]]; then
                    files_modified="${files_modified}, ${file_match}"
                else
                    files_modified="$file_match"
                fi
            fi
        fi

        # Check for test execution patterns
        if echo "$line" | grep -qiE '(running tests|test passed|tests passed|all tests|test.*success|bash -n|shellcheck|syntax check)'; then
            tests_run="yes"
        fi

        # Check for error patterns
        if echo "$line" | grep -qiE '(error:|failed:|failure:|exception:)'; then
            errors_found="yes"
        fi
    done <<< "$output"

    # Build summary output
    local summary_lines=()

    if [[ -n "$files_created" ]]; then
        summary_lines+=("  Files created: $files_created")
    fi

    if [[ -n "$files_modified" ]]; then
        summary_lines+=("  Files modified: $files_modified")
    fi

    if [[ "$tests_run" == "yes" ]]; then
        summary_lines+=("  Tests/validation: executed")
    fi

    if [[ "$errors_found" == "yes" ]]; then
        summary_lines+=("  ⚠ Errors detected in output")
    fi

    # If no specific actions found, provide generic summary
    if [[ ${#summary_lines[@]} -eq 0 ]]; then
        # Try to extract task description from PRD update
        local task_summary
        task_summary=$(echo "$output" | grep -oE 'Task [0-9]+\.[0-9]+[^:]*' | head -1)
        if [[ -n "$task_summary" ]]; then
            summary_lines+=("  Working on: $task_summary")
        else
            summary_lines+=("  Iteration completed (see full log for details)")
        fi
    fi

    # Output the summary
    for line in "${summary_lines[@]}"; do
        echo "$line"
    done
}

# Filter and display output for terminal, log full to file
# Usage: ralph_filter_output "session_id" 5 "full output"
# Displays concise summary to terminal, logs full output to file
ralph_filter_output() {
    local session_id="$1"
    local iteration="$2"
    local output="$3"

    # Always log the full output to file
    ralph_log_full_output "$session_id" "$iteration" "$output"

    # Check if filtering is enabled
    if [[ "$RALPH_FILTER_OUTPUT" != "true" ]]; then
        # Filtering disabled, output everything
        echo "$output"
        return 0
    fi

    # Extract and display concise summary
    local summary
    summary=$(ralph_extract_output_summary "$output")

    if [[ -n "$summary" ]]; then
        echo "$summary"
    fi

    # Always indicate where full output can be found
    ralph_debug "Full output logged to: $(ralph_get_full_output_log_path)"
}

# Get output statistics from full output
# Usage: stats=$(ralph_get_output_stats "full output")
# Returns: line count and character count
ralph_get_output_stats() {
    local output="$1"
    local line_count
    local char_count

    line_count=$(echo "$output" | wc -l | tr -d ' ')
    char_count=$(echo "$output" | wc -c | tr -d ' ')

    echo "lines=$line_count chars=$char_count"
}

# Export output filtering functions
export -f ralph_get_full_output_log_path
export -f ralph_log_full_output
export -f ralph_extract_output_summary
export -f ralph_filter_output
export -f ralph_get_output_stats
