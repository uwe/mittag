build:
	docker build -t mittag .

run:
	docker run -d -p 127.0.0.1:8002:8080 --name mittag --link mysql:mysql mittag

bash:
	docker run --rm -t -i -p 127.0.0.1:8002:8080 --name mittag --link mysql:mysql mittag /bin/bash
