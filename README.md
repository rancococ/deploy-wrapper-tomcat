# docker-wrapper-tomcat

## 项目介绍
docker-wrapper-tomcat

1. include wrapper-v3.5.41
2. support alpine and centos
3. usage:
   - docker run -it --rm --name wrapper-tomcat-1.0.0-alpine -p 18080:8080 -p 10001:10001 -p 10002:10002 registry.cn-hangzhou.aliyuncs.com/rancococ/wrapper:wrapper-3.5.41.1-tomcat-8.5.40.1-alpine
   - docker run -it --rm --name wrapper-tomcat-1.0.0-centos -p 18080:8080 -p 10001:10001 -p 10002:10002 registry.cn-hangzhou.aliyuncs.com/rancococ/wrapper:wrapper-3.5.41.1-tomcat-8.5.40.1-centos
