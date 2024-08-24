import re
from pathlib import Path
from pprint import pprint

import tomllib

INC_PATTERN = r'##include\s+"(.*?)"\s*'

# Cache for included files to avoid re-reading and re-parsing
include_cache = {}


class TedParser:
    def __init__(self, toml_path: Path) -> None:
        self.config = self.toml_parse(toml_path)

    @property
    def design(self) -> dict:
        return self.config["design"]

    @property
    def target(self) -> dict:
        return self.config["target"]


    def __toml_subcall(self, match: re.Match, base_path: Path) -> str:
        include_file_path = base_path / match.group(1)

        # Use cached content if available
        if include_file_path in include_cache:
            return include_cache[include_file_path]

        if not include_file_path.exists():
            print(f"File {include_file_path} not found. Skipping include.")
            return ""

        # Cache and return the content of the included file
        include_cache[include_file_path] = self.__toml_subreplace(include_file_path)
        return include_cache[include_file_path]

    def __toml_subreplace(self, file_path: Path) -> str:
        try:
            content = file_path.read_text()
            preprocessed_content = re.sub(
                INC_PATTERN,
                lambda match: self.__toml_subcall(match, file_path.parent),
                content,
            )
            return preprocessed_content
        except Exception as e:
            print(f"Error processing file {file_path}: {e}")
            return ""

    def toml_parse(self, ted_path: Path) -> dict:
        ted_content = self.__toml_subreplace(ted_path)
        try:
            return tomllib.loads(ted_content)
        except Exception as e:
            print(f"Error parsing TOML content: {e}")
            return {}


if __name__ == "__main__":
    file_path = Path("test/top.toml")  # Replace with your TOML file path
    result = TedParser(file_path.absolute())
    pprint(result)
