FROM atlassian/confluence-server:6.6
# 传入破解补丁
ADD ./atlassian-extras-decoder-v2-3.2.jar ${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.2.jar
ADD ./mysql-connector-java-5.1.45-bin.jar ${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib/mysql-connector-java-5.1.45-bin.jar
# 设置文件属组
RUN chown -R ${RUN_USER}:${RUN_GROUP} ${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.2.jar
RUN chown -R ${RUN_USER}:${RUN_GROUP} ${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib/mysql-connector-java-5.1.45-bin.jar
CMD ["/entrypoint.sh", "-fg"]