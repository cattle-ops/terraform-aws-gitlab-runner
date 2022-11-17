import subprocess
import os

root_module_dir = os.getcwd()

r = subprocess.run(
    [
        "terraform-docs",
        root_module_dir,
        "-c",
        ".tfdocs-config.yml",
        "--output-file",
        "README.md",
    ],
    capture_output=True,
)
print(r.stderr.decode())
print(r.stdout.decode())
if r.returncode != 0:
    exit(r.returncode)

examples_dir = os.path.join(os.getcwd(), "examples")

example_dirs = [f.path for f in os.scandir(examples_dir) if f.is_dir()]
for example_dir in example_dirs:
    r = subprocess.run(
        [
            "terraform-docs",
            example_dir,
            "-c",
            "examples/.tfdocs-examples-config.yml",
            "--output-file",
            "README.md",
        ],
        capture_output=True,
    )
    print(r.stderr.decode())
    print(r.stdout.decode())
    if r.returncode != 0:
        exit(r.returncode)
