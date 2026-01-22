DB_URL=postgresql://root:123456@localhost:5432/simple_bank?sslmode=disable

postgres:
	docker run --name postgres12 -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=123456 -d postgres:12-alpine

createdb:
	docker exec -it postgres12 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres12 dropdb simple_bank

migrateup:
	$(eval STEP := $(filter-out $@,$(MAKECMDGOALS)))
	migrate -path ./db/migration -database "$(DB_URL)" -verbose up $(STEP)

migratedown:
	@# 提取参数，无参数时默认1
	$(eval STEP := $(filter-out $@,$(MAKECMDGOALS)))
	migrate -path ./db/migration -database "$(DB_URL)" -verbose down $(if $(STEP),$(STEP),1)

migrateversion:
	migrate -path ./db/migration -database "$(DB_URL)" version

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

# 伪目标声明 (防止和同名文件冲突)
.PHONY: postgres createdb dropdb migrateup migratedown sqlc test
