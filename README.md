- ansible install
```bash
dnf install -y epel-release
dnf install -y ansible

git clone
cd k8s_upgrade_ansible
```
- inventory 설정
	- inventory/hosts ip 부분 수정
- ssh 키배포
	- SSH_SETUP.md 파일 참고해서 1. 2. 까지만 진행
- ansible ping test
```bash
ansible all -m ping
```
- playbook 실행 (k8s 클러스터 업그레이드)
```bash
ansible-playbook -i inventory/hosts playbook.yml -v
```
