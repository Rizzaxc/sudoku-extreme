"""
generate_puzzles.py — Generates 5000 extreme-difficulty Sudoku puzzles.
  2500 via qqwing (expert difficulty)
  2500 via tdoku generator + solver

Usage:
  python generate_puzzles.py \
    [--tdoku-gen-bin PATH]    path to tdoku generator binary
    [--tdoku-solver-bin PATH] path to tdoku solver binary
    [--java PATH]             path to java executable (default: 'java')
    [--jar PATH]              path to qqwing jar (default: qqwing-1.3.4.jar)
    [--out-dir PATH]          output directory (default: assets/puzzles)
    [--batch-size N]          qqwing puzzles per subprocess call (default: 50)

Output:
  assets/puzzles/chunk_00.csv  ...  chunk_49.csv
  Each file: header + 100 rows of id,clues,solution,source
"""

import argparse
import csv
import os
import subprocess
import sys
from pathlib import Path

TOTAL = 5000
QQWING_COUNT = 2500
TDOKU_COUNT = 2500
CHUNK_SIZE = 100


def parse_args():
    p = argparse.ArgumentParser(description="Generate sudoku puzzle CSV assets")
    p.add_argument("--tdoku-gen-bin", default=None)
    p.add_argument("--tdoku-solver-bin", default=None)
    p.add_argument("--java", default="java")
    p.add_argument("--jar", default="qqwing-1.3.4.jar")
    p.add_argument("--out-dir", default="assets/puzzles")
    p.add_argument("--batch-size", type=int, default=100)
    p.add_argument(
        "--qqwing-only",
        action="store_true",
        help="Generate all 5000 using qqwing (use when tdoku binary unavailable)",
    )
    return p.parse_args()


# ---------------------------------------------------------------------------
# qqwing
# ---------------------------------------------------------------------------

def generate_qqwing(java: str, jar: str, total: int, batch_size: int) -> list[tuple[str, str]]:
    """Returns list of (clues_81, solution_81) using qqwing."""
    results: list[tuple[str, str]] = []
    jar_path = str(Path(jar).resolve())

    while len(results) < total:
        need = min(batch_size, total - len(results))
        try:
            proc = subprocess.run(
                [java, "-jar", jar_path,
                 "--generate", str(need),
                 "--difficulty", "expert",
                 "--one-line", "--solution"],
                capture_output=True, text=True, check=True, timeout=120,
            )
        except subprocess.CalledProcessError as e:
            print(f"qqwing failed: {e.stderr}", file=sys.stderr)
            sys.exit(1)

        lines = [l.strip() for l in proc.stdout.splitlines() if l.strip()]
        i = 0
        while i + 1 < len(lines):
            puzzle_line = lines[i].replace(".", "0")
            sol_line = lines[i + 1]
            if len(puzzle_line) == 81 and len(sol_line) == 81 and sol_line.isdigit():
                results.append((puzzle_line, sol_line))
            i += 2

        print(f"  qqwing: {len(results)}/{total}", end="\r", flush=True)

    print()
    return results[:total]


# ---------------------------------------------------------------------------
# tdoku
# ---------------------------------------------------------------------------

def detect_tdoku_output_format(gen_bin: str) -> str:
    """
    Run the generator with 1 puzzle and inspect stdout to detect format.
    tdoku generate programs can output:
      - 81-char puzzle string only (one per line)
      - "puzzle solution" separated by space or comma
    Returns 'puzzle_only' or 'puzzle_solution'.
    """
    try:
        proc = subprocess.run(
            [gen_bin, "1"],
            capture_output=True, text=True, timeout=30,
        )
        line = proc.stdout.strip().splitlines()[0] if proc.stdout.strip() else ""
        if len(line) == 81:
            return "puzzle_only"
        parts = line.split()
        if len(parts) == 2 and len(parts[0]) == 81 and len(parts[1]) == 81:
            return "puzzle_solution"
        # Try comma
        parts = line.split(",")
        if len(parts) >= 2 and len(parts[0]) == 81 and len(parts[1]) == 81:
            return "puzzle_solution_csv"
    except Exception:
        pass
    return "puzzle_only"


def solve_with_tdoku(solver_bin: str, clue_lines: list[str]) -> list[str]:
    """Pipes clues through tdoku solver. Returns solution strings."""
    input_text = "\n".join(clue_lines) + "\n"
    try:
        proc = subprocess.run(
            [solver_bin],
            input=input_text,
            capture_output=True, text=True, check=True, timeout=300,
        )
    except subprocess.CalledProcessError as e:
        print(f"tdoku solver failed: {e.stderr}", file=sys.stderr)
        sys.exit(1)

    solutions = []
    for line in proc.stdout.splitlines():
        line = line.strip()
        if len(line) == 81 and line.isdigit():
            solutions.append(line)
    return solutions


def generate_tdoku(
    gen_bin: str,
    solver_bin: str | None,
    total: int,
    batch_size: int,
) -> list[tuple[str, str]]:
    """Returns list of (clues_81, solution_81) using tdoku generator."""
    fmt = detect_tdoku_output_format(gen_bin)
    print(f"  tdoku output format detected: {fmt}")

    results: list[tuple[str, str]] = []

    while len(results) < total:
        need = min(batch_size, total - len(results))
        try:
            proc = subprocess.run(
                [gen_bin, str(need)],
                capture_output=True, text=True, check=True, timeout=300,
            )
        except subprocess.CalledProcessError as e:
            print(f"tdoku generator failed: {e.stderr}", file=sys.stderr)
            sys.exit(1)

        raw_lines = [l.strip() for l in proc.stdout.splitlines() if l.strip()]

        if fmt == "puzzle_solution":
            for line in raw_lines:
                parts = line.split()
                if len(parts) == 2 and len(parts[0]) == 81 and len(parts[1]) == 81:
                    results.append((parts[0].replace(".", "0"), parts[1]))
        elif fmt == "puzzle_solution_csv":
            for line in raw_lines:
                parts = line.split(",")
                if len(parts) >= 2 and len(parts[0]) == 81 and len(parts[1]) == 81:
                    results.append((parts[0].replace(".", "0"), parts[1]))
        else:
            # puzzle_only — need solver
            clues = [l.replace(".", "0") for l in raw_lines if len(l) == 81]
            if not clues:
                continue
            if solver_bin:
                sols = solve_with_tdoku(solver_bin, clues)
            else:
                print(
                    "ERROR: tdoku generator outputs puzzle-only but no --tdoku-solver-bin supplied.",
                    file=sys.stderr,
                )
                sys.exit(1)
            for clue, sol in zip(clues, sols):
                if len(sol) == 81:
                    results.append((clue, sol))

        print(f"  tdoku: {len(results)}/{total}", end="\r", flush=True)

    print()
    return results[:total]


# ---------------------------------------------------------------------------
# CSV writing
# ---------------------------------------------------------------------------

def write_chunks(all_puzzles: list[dict], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for chunk_idx in range(TOTAL // CHUNK_SIZE):
        start = chunk_idx * CHUNK_SIZE
        end = start + CHUNK_SIZE
        chunk = all_puzzles[start:end]
        fname = out_dir / f"chunk_{chunk_idx:02d}.csv"
        with open(fname, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["id", "clues", "solution", "source"])
            writer.writeheader()
            writer.writerows(chunk)
    print(f"Wrote {TOTAL // CHUNK_SIZE} chunk files to {out_dir}/")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_args()
    out_dir = Path(args.out_dir)

    all_puzzles: list[dict] = []

    # qqwing: IDs 0–2499
    print(f"Generating {QQWING_COUNT} qqwing puzzles (expert difficulty)...")
    qqwing_pairs = generate_qqwing(args.java, args.jar, QQWING_COUNT, args.batch_size)
    for i, (clues, sol) in enumerate(qqwing_pairs):
        all_puzzles.append({"id": i, "clues": clues, "solution": sol, "source": "qqwing"})
    print(f"  qqwing done: {len(qqwing_pairs)} puzzles")

    # tdoku: IDs 2500–4999
    if args.qqwing_only:
        print(f"--qqwing-only: generating second {TDOKU_COUNT} with qqwing (source='qqwing_2')")
        tdoku_pairs = generate_qqwing(args.java, args.jar, TDOKU_COUNT, args.batch_size)
        for i, (clues, sol) in enumerate(tdoku_pairs):
            all_puzzles.append({
                "id": QQWING_COUNT + i,
                "clues": clues,
                "solution": sol,
                "source": "qqwing_2",
            })
    else:
        if not args.tdoku_gen_bin:
            print(
                "ERROR: --tdoku-gen-bin is required (or use --qqwing-only for a qqwing-only run).",
                file=sys.stderr,
            )
            sys.exit(1)

        if not os.path.isfile(args.tdoku_gen_bin):
            print(f"ERROR: tdoku generator not found at: {args.tdoku_gen_bin}", file=sys.stderr)
            sys.exit(1)

        print(f"Generating {TDOKU_COUNT} tdoku puzzles...")
        tdoku_pairs = generate_tdoku(
            args.tdoku_gen_bin,
            args.tdoku_solver_bin,
            TDOKU_COUNT,
            args.batch_size,
        )
        for i, (clues, sol) in enumerate(tdoku_pairs):
            all_puzzles.append({
                "id": QQWING_COUNT + i,
                "clues": clues,
                "solution": sol,
                "source": "tdoku",
            })
        print(f"  tdoku done: {len(tdoku_pairs)} puzzles")

    write_chunks(all_puzzles, out_dir)
    print("All done!")


if __name__ == "__main__":
    main()
