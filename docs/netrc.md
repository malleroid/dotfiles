# ~/.netrc

Machine credentials file used by CLI tools (mise, curl, etc).

## Setup

```bash
cp docs/netrc.example ~/.netrc
chmod 600 ~/.netrc
# Replace placeholder values with real credentials
```

## Note

The netrc format does not support comments. Do not include `#` lines.
