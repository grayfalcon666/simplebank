ifneq (,$(wildcard ./app.env))
    include ./app.env
    export
endif

DB_URL=$(DB_SOURCE)

postgres:
	docker run --name postgres12 --network bank-network -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=123456 -d postgres:12-alpine

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

server:
	go run main.go

mockgen:
	mockgen -package mockdb -destination ./db/mock/store.go ./db/sqlc Store

# 伪目标声明 (防止和同名文件冲突)
.PHONY: postgres createdb dropdb migrateup migratedown sqlc test server

# 处理Makefile传参的兼容逻辑（比如make migrateup 2时，忽略多余参数）
%:
	@: