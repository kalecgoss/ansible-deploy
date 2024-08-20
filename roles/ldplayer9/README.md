# Роль LDPlayer9

Для установки/обновления LDPlayer необходимо подключить роль к плейбуку:

```ansible
  roles:
    - { role: roles/ldplayer9 }
```

Для полного удаления всех установленных LDPLayer-ов используйте параметр:

```ansible
  roles:
    - { role: roles/ldplayer9, action: uninstall }
```

Для ротации эмулятора (удаление старого, создание нового)

```ansible
  roles:
    - { role: roles/ldplayer9, action: rotation }
```
