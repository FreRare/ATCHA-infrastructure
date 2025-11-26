# ATCHA Infrastructure

Contains DevOps workflows for the whole ATCHA project  

For easy startup:
- Clone the main repository at: https://github.com/FreRare/ATCHA-core on the main branch
- Don't forget to recirsively add all submodules!
- Go to the folder backend/terraform
- Run the startup script like: ./run.sh

This process will create all docker images and start them using terraform, listing all useful endpoints and keeping the application logs visible.


## Bakcend

This for now contains a terraform infrastructure to run the application and to be abel to monitor different metrics and logs.

The infrastructure contains:
- Prometheus (for system and API metrics collection)
- Grafana (for great and stylish data visualization)
- Graylog (for logging services)

