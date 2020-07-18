
# Runs Tests
FROM node:12-alpine as tester
WORKDIR /usr/src/app
COPY . .
RUN npm ci
RUN npm test

#build base 
FROM node:12-alpine as builder
COPY package*.json ./
RUN npm ci --only=production

#config and run
FROM node:12-alpine
WORKDIR /usr/src/app
COPY --from=builder node_modules node_modules
COPY . .

ARG PORT_ARG=80
ENV PORT=$PORT_ARG
EXPOSE $PORT_ARG
ARG COMMIT_SHA
RUN echo $COMMIT_SHA > metadata
ENTRYPOINT [ "npm", "start" ]