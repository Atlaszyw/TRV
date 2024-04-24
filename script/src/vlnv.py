from functools import total_ordering


@total_ordering
class Vlnv:
    def __init__(self, vlnv_str: str, default_relation='>='):
        if not vlnv_str:
            raise SyntaxError('Core name is empty string')

        self.conflict = vlnv_str.startswith('!')
        _vlnv_str = vlnv_str[1:] if self.conflict else vlnv_str

        self.relation = self._parse_relation(_vlnv_str)
        _vlnv_str = _vlnv_str.lstrip('>=<~^=')

        parts = _vlnv_str.split(':')
        self.vendor, self.library, self.name, self.version, self.revision = (
            self._parse_parts(parts)
        )

        self._finalize_version(default_relation)
        self.sanitized_name = self.__str__().lstrip(':').replace(':', '_')

    @property
    def library_name(self):
        return self.library

    @staticmethod
    def _parse_relation(s) -> str:
        for rel in ['>=', '<=', '>', '<', '~', '^', '=']:
            if s.startswith(rel):
                return '==' if rel == '=' else rel
        return ''

    @staticmethod
    def _parse_parts(parts):
        def _is_rev(s):
            return s.startswith('r') and s[1:].isdigit()

        revision = 0
        version = ''

        if len(parts) == 1:
            return '', '', parts[0], version, revision

        if len(parts) >= 3:
            vendor, library, name = parts[:3]
        else:
            raise SyntaxError(f"Illegal core name '{parts}'")

        if len(parts) == 4:
            v_parts = parts[3].split('-')
            if _is_rev(v_parts[-1]):
                revision = int(v_parts.pop()[1:])
            version = '-'.join(v_parts)

        return vendor, library, name, version, revision

    def _finalize_version(self, default_relation):
        if self.version or self.revision > 0:
            self.relation = self.relation if self.relation else '=='
            self.version = self.version if self.version else '0'
        else:
            if self.relation:
                raise SyntaxError(
                    f"{self}: '{self.relation}' operator requires a version"
                )
            self.version = '0'
            self.relation = default_relation

    def __str__(self):
        revision_str = f'-r{self.revision}' if self.revision > 0 else ''
        return f'{self.vendor}:{self.library}:{self.name}:{self.version}{revision_str}'

    def __eq__(self, other):
        return (self.vendor, self.library, self.name, self.version, self.revision) == (
            other.vendor,
            other.library,
            other.name,
            other.version,
            other.revision,
        )

    def __lt__(self, other):
        return (self.vendor, self.library, self.name, self.version, self.revision) < (
            other.vendor,
            other.library,
            other.name,
            other.version,
            other.revision,
        )

    def depstr(self):
        relation = '' if self.relation == '==' else self.relation
        return relation + str(self)
