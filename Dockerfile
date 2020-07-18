
# Runs Tests
FROM node:12-alpine as tester
WORKDIR /usr/src/app
COPY . .
RUN npm ci
RUN npm test

FROM node:12-alpine as builder
COPY package*.json ./
RUN npm ci --only=production

FROM node:12-alpine
ARG PORT_ARG=80
ENV PORT=$PORT_ARG 
WORKDIR /usr/src/app

COPY --from=builder node_modules node_modules
COPY . .

EXPOSE $PORT_ARG
CMD [ "npm", "start" ]