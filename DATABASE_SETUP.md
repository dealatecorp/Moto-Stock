# Motorstock XAMPP MySQL Setup

1. Start XAMPP Apache and MySQL.
2. Because another MySQL service is already using `3306`, configure XAMPP MySQL to run on `3307`.
3. Open phpMyAdmin or the MySQL console.
4. Import `api/schema.sql`.
5. Put this project inside XAMPP `htdocs`, for example:
   `C:\xampp\htdocs\bikeshowroom`
6. Open:
   `http://localhost/bikeshowroom/index.html`

The frontend calls `api/api.php`, which connects to:

```php
host: 127.0.0.1
port: 3307
database: motorstock_db
user: root
password:root
```

The app is configured to try the XAMPP `root` password first. If this machine still has the XAMPP/default empty password, it falls back automatically.

Seed logins:

```text
Admin: admin@gmail.com / admin
Staff: vizag_a / staff123
Staff: rajesh_b / staff123
```

Staff users can login only during their assigned shift:

```text
Shift A: 10 AM to 3 PM
Shift B: 4 PM to 9 PM
```

This machine currently has another MySQL server listening on `3306`. If XAMPP MySQL does not start, move XAMPP to `3307`:

```text
1. Close XAMPP completely.
2. Open C:\xampp\mysql\bin\my.ini.
3. Change both port entries from 3306 to 3307:
   port=3307
4. Open C:\xampp\phpMyAdmin\config.inc.php and add:
   $cfg['Servers'][$i]['port'] = '3307';
5. Start XAMPP MySQL again.
6. Import api/schema.sql into phpMyAdmin.
```
