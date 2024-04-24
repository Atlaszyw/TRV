import json
import os
import re
import tomllib
from pathlib import Path

from loguru import logger
from toml_parser import toml_parse
from vlnv import Vlnv

INC_PATTERN = r'##include\s+"(.*?)"\s*'

# Cache for included files to avoid re-reading and re-parsing
include_cache = {}


@logger.catch
class Tedatabase:
    def __init__(self, tedconfig=Path('ted.toml')) -> None:
        self.dbdir = Path('.ted')
        self.dbdir.mkdir(parents=True, exist_ok=True)
        self.tooldir = self.dbdir / 'tools'
        self.toptedfile = tedconfig

        if tedconfig.exists():
            logger.info(f'Using {tedconfig} as config file')

        config = self.__toml_parse(tedconfig)
        self.ip = TedIP(config)

        self.default_tool: str = config['default_tool']
        self.__cache_tools(config['target'])

    def __cache_tools(self, targetconfig: dict):
        Path(targetconfig['work_dir']).mkdir(parents=True, exist_ok=True)
        if self.tooldir.stat().st_mtime < self.toptedfile.stat().st_mtime:
            for k, v in targetconfig['tools']:
                kfile = self.tooldir / f'{k}'
                with open(kfile, mode='w', encoding='utf-8') as f:
                    json.dump(v, f)
            (self.tooldir / 'default.json').symlink_to(
                self.tooldir / f'{self.default_tool}'
            )
        else:
            logger.info('using exsisting cache file')

    def __toml_subcall(self, match: re.Match, base_path: Path) -> str:
        include_file_path = base_path / match.group(1)

        # Use cached content if available
        if include_file_path in include_cache:
            return include_cache[include_file_path]

        if not include_file_path.exists():
            print(f'File {include_file_path} not found. Skipping include.')
            return ''

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
            print(f'Error processing file {file_path}: {e}')
            return ''

    def __toml_parse(self, ted_path: Path) -> dict:
        ted_content = self.__toml_subreplace(ted_path)
        try:
            return tomllib.loads(ted_content)
        except Exception as e:
            print(f'Error parsing TOML content: {e}')
            return {}


class Tedesign:
    def __init__(self, options: dict) -> None:
        self.top: str = options['top']
        self.filelists: dict = options['filelists']
        self.svlist = Tedesign._path_parse(self.filelists['sv'])
        self.vlist = Tedesign._path_parse(self.filelists['v'])
        self.inc_dir: list[Path] = Tedesign._path_parse(options['inc_dir'])
        self.ext_dir: list[Path] = Tedesign._path_parse(options['ext_dir'])
        self.rom: list[Path] = options['rom']
        self.param: dict = options['param']
        self.macros = options['macros']
        self.depend = options['depend']

    @staticmethod
    def _path_parse(paths: list[str]) -> list[Path]:
        return [p for path in paths for p in Tedesign._dir_parse(path)]

    @staticmethod
    def _dir_parse(path: str) -> list[Path]:
        path = os.path.expandvars(path)

        return (
            [Path(path)]
            if path.endswith('...')
            else [Path(path)] + [p for p in Path(path[:-3]).rglob('*') if p.is_dir()]
        )


class TedIP:
    def __init__(self, options):
        self.vlnv = Vlnv(options['VLNV'])
        self.desc = options['description']
        self.design = Tedesign(options['design'])


if __name__ == '__main__':
    toml_dict = toml_parse(Path('test/top.toml'))
    IP = TedIP(toml_dict)
    target = TedTarget(toml_dict['target'])
