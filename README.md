# fullstack e-commerce   con rails 
* Ruby version
```bash
ruby 3.3.0
```
* versión de rails 
```bash
rails 7.1.2
```
* Instalar las dependencias
```bash
bundle install
```
* Crear la migración 
```bash
rails db:migrate
```
* Correr el proyecto
```bash
rails s
```

## apuntes
### para crear admin 
```bash
rails generate Admin
```
### para crear un usuario admin desde consola de rails 
```bash
rails c
```
```bash
Admin.create(email: 'admin@example.com', password: 'password')
```
```bash
rails s
```
### ruta por defecto de admin 
```bash
127.0.0.1:3000/admins/sign_in
```

