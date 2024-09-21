# 1. Usamos la imagen base que se especifica en el comando
FROM lambci/lambda:build-python3.7

# 2. Establecemos el directorio de trabajo donde se colocarán los archivos
WORKDIR /var/task

# 3. Definimos las variables de entorno necesarias
ENV ODBCINI=/var/task
ENV ODBCSYSINI=/var/task

# 4. Instalamos dependencias básicas y necesarias
RUN yum install -y curl openssl nano git unixODBC-devel \
    && yum clean all

# 5. Descargamos, descomprimimos e instalamos unixODBC 2.3.7
RUN curl -O ftp://ftp.unixodbc.org/pub/unixODBC/unixODBC-2.3.7.tar.gz \
    && tar xvzf unixODBC-2.3.7.tar.gz \
    && cd unixODBC-2.3.7 \
    && ./configure && make && make install \
    && cd /var/task && rm -rf unixODBC-2.3.7 unixODBC-2.3.7.tar.gz

# 6. Instalamos las librerías de Python necesarias
COPY requirements.txt ./
RUN pip install -r requirements.txt -t .

# 7. Copiamos los archivos de configuración
COPY config.json ./
COPY odbc.ini ./
COPY query.py ./

# 8. Configuramos Git y clonamos el repositorio desde GitHub
RUN git config --global user.name "sergio239" && \
    git config --global user.email "sergio.cubillos@outlook.com" && \
    git clone https://github.com/sergiod239/xactlydriver.git

# 9. Descomprimimos el archivo descargado y lo instalamos en el directorio especificado
RUN cd xactlydriver && \
    tar xvf delta-xodbc-driver-linux-2.1.5-RELEASE.tgz && \
    mkdir -p /var/task/xodbc && \
    install -t /var/task/xodbc libxodbc.so && \
    chmod 755 /var/task/xodbc/libxodbc.so

# 10. Definimos el punto de entrada para ejecutar el contenedor
ENTRYPOINT ["python", "query.py"]