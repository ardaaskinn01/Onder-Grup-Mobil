FROM node:latest

WORKDIR /nodeapp

# wait-for-it.sh dosyasını kopyalayın ve yürütme izni verin
COPY wait-for-it.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wait-for-it.sh

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

# wait-for-it.sh dosyasını başlatma komutuna ekleyin
CMD ["sh", "-c", "/usr/local/bin/wait-for-it.sh mysql-container:3306 -- npm start"]
