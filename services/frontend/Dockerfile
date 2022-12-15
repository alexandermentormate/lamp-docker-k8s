FROM node:15-alpine

RUN npm install -g http-server

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# Flask api
RUN ROOT_API=http://localhost:5000 npm run build

EXPOSE 8080

CMD [ "http-server", "dist" ]
