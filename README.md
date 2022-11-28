# elasticsearch-github-actions

setup elasticsearch in your github actions' workflow

## Usage
```yaml
steps:
- name: Configure sysctl limits
  run: |
    sudo swapoff -a
    sudo sysctl -w vm.swappiness=1
    sudo sysctl -w fs.file-max=262144
    sudo sysctl -w vm.max_map_count=262144

- uses: jonasge/elasticsearch-github-actions@1
  with:
    stack-version: '8.2.0'
    plugins: 'ingest-attachment'
```
