import re
from pathlib import Path
from pprint import pprint

import tomllib

INC_PATTERN = r'##include\s+"(.*?)"\s*'

# Cache for included files to avoid re-reading and re-parsing
include_cache = {}


def _toml_subcall(match: re.Match, base_path: Path) -> str:
    include_file_path = base_path / match.group(1)

    # Use cached content if available
    if include_file_path in include_cache:
        return include_cache[include_file_path]

    if not include_file_path.exists():
        print(f"File {include_file_path} not found. Skipping include.")
        return ""

    # Cache and return the content of the included file
    include_cache[include_file_path] = _toml_subreplace(include_file_path)
    return include_cache[include_file_path]


def _toml_subreplace(file_path: Path) -> str:
    try:
        content = file_path.read_text()
        preprocessed_content = re.sub(
            INC_PATTERN, lambda match: _toml_subcall(match, file_path.parent), content
        )
        return preprocessed_content
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")
        return ""


def toml_parse(ted_path: Path) -> dict:
    ted_content = _toml_subreplace(ted_path)
    try:
        return tomllib.loads(ted_content)
    except Exception as e:
        print(f"Error parsing TOML content: {e}")
        return {}


if __name__ == "__main__":
    file_path = Path("test/top.toml")  # Replace with your TOML file path
    result = toml_parse(file_path.absolute())
    pprint(result)
