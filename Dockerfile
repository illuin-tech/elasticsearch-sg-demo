# https://github.com/elastic/elasticsearch-docker
FROM docker.elastic.co/elasticsearch/elasticsearch:6.4.2

RUN yum -y update && yum -y install git

# Create the folder for elasticsearch config
RUN mkdir /usr/share/elasticsearch/config/sg
RUN mkdir /usr/share/elasticsearch/config/sg-certificates

# Search Guard plugin
# https://github.com/floragunncom/search-guard/wiki
RUN elasticsearch-plugin install --batch com.floragunn:search-guard-6:6.4.2-23.1 \
	&& chmod +x plugins/search-guard-6/tools/*.sh \
	&& chown -R elasticsearch config/

# Install wait-for-it
RUN git clone https://github.com/vishnubob/wait-for-it.git /wait-for-it

# Install demo config
RUN plugins/search-guard-6/tools/install_demo_configuration.sh -y

# Copy entrypoint
COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh
EXPOSE 9200
USER elasticsearch

# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu
ENTRYPOINT "./entrypoint.sh"
