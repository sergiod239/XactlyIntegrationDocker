import pyodbc
import json
import boto3
import pandas as pd
from io import StringIO

def run_query():
    # Cargamos las credenciales y la consulta desde el archivo de configuración
    with open('config.json') as config_file:
        config = json.load(config_file)

    ODBC_UID = config['ODBC_UID']
    ODBC_PWD = config['ODBC_PWD']
    QUERY = config['QUERY']
    bucket_name = config['BUCKET_NAME']  # Nombre del bucket S3
    file_name = config['FILE_NAME']        # Nombre del archivo a subir

    try:
        cnxn = pyodbc.connect(f'DSN=api-production;UID={ODBC_UID};PWD={ODBC_PWD}')
        cursor = cnxn.cursor()
        print('Ejecutando la consulta:', QUERY)
        cursor.execute(QUERY)
        rows = cursor.fetchall()

        # Convertir los resultados a un DataFrame
        columns = [column[0] for column in cursor.description]
        data = pd.DataFrame.from_records(rows, columns=columns)

        # Subir los resultados a S3
        upload_to_s3(data, bucket_name, file_name)

    except Exception as e:
        print('Ocurrió un error al consultar o subir a S3:', e)
    finally:
        cnxn.close()

def upload_to_s3(data, bucket_name, file_name):
    # Crear un cliente S3
    s3_client = boto3.client('s3')

    # Convertir DataFrame a CSV en memoria
    csv_buffer = StringIO()
    data.to_csv(csv_buffer, index=False)

    # Subir el CSV a S3
    s3_client.put_object(Bucket=bucket_name, Key=file_name, Body=csv_buffer.getvalue())
    print(f'Datos subidos a S3 en el bucket {bucket_name} con el nombre {file_name}.')

if __name__ == "__main__":
    run_query()