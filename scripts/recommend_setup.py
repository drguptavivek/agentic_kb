import platform
import re
import shutil
import subprocess


def has_cmd(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def get_cuda_version() -> str | None:
    if not has_cmd("nvidia-smi"):
        return None
    try:
        result = subprocess.run(
            ["nvidia-smi"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
            text=True,
        )
        match = re.search(r"CUDA Version:\s+([0-9.]+)", result.stdout)
        if match:
            return match.group(1)
        return None
    except Exception:
        return None


def cuda_wheel_hint(cuda_version: str | None) -> str:
    if not cuda_version:
        return "cu121"
    major_minor = ".".join(cuda_version.split(".")[:2])
    if major_minor.startswith("12."):
        return "cu121"
    if major_minor.startswith("11."):
        return "cu118"
    return "cu121"


def main() -> None:
    system = platform.system().lower()
    cuda_version = get_cuda_version()
    cuda_hint = cuda_wheel_hint(cuda_version)

    print("Recommended setup commands (copy-paste):\n")

    if system == "darwin":
        print("# macOS (Apple Silicon or Intel)")
        print("uv add faiss-cpu numpy sentence-transformers tqdm")
        print("# Optional: MPS-backed torch for faster indexing on Apple Silicon")
        print("uv add torch")
    elif system == "windows":
        print("# Windows")
        print("uv add faiss-cpu numpy sentence-transformers tqdm")
        print("# Optional: CUDA torch if you have an NVIDIA GPU")
        print("# Example (choose the correct CUDA version for your driver):")
        print("# uv add torch --index-url https://download.pytorch.org/whl/cu121")
    else:
        print("# Linux")
        print("uv add faiss-cpu numpy sentence-transformers tqdm")
        if cuda_version:
            print(f"# NVIDIA GPU detected (CUDA {cuda_version})")
            print("# Option A: CUDA-enabled torch")
            print(
                f"# uv add torch --index-url https://download.pytorch.org/whl/{cuda_hint}"
            )
            print("# Option B: faiss-gpu (Linux only; may require CUDA toolkit)")
            print("# uv add faiss-gpu")
        else:
            print("# Optional: CUDA torch if you have an NVIDIA GPU")
            print(
                f"# uv add torch --index-url https://download.pytorch.org/whl/{cuda_hint}"
            )

    print("\nThen run:")
    print("uv run python scripts/index_kb.py")
    print('uv run python scripts/search.py "your query"')


if __name__ == "__main__":
    main()
