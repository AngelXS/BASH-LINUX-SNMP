#!/bin/bash
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#X 																													  X
#X					        ESCUELA POLITECNICA NACIONAL - TECNOLOGIAS DE LA INFORMACION							  X
#X 																													  X
#X   Escrito por: Luis Angel Sanguano	                                                                              X
#X 																													  X                                    
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#Almacenar el valor de la IP Ingresada
	#------------------------
	ip=$1
	#------------------------
#----------------------------------------------------------------------------------------------------------------------
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\CONFIGURACIONES INICIALES\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#----------------------------------------------------------------------------------------------------------------------
#Condicional para ferificar que se cumpla la condicion de tener 3 argumentos de entrada
if [ "$1" == "" ] 
then

	echo "+______________________________________+"
	echo "|                                      |"
	echo "| Se requieren 1 argumento de entrada  |"
	echo "| Ejemplo: 192.168.100.44              |"
	echo "+______________________________________+"
	echo
	exit
fi

#----------------------------------------------------------------------------------------------------------------------
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\FUNCIONBULK()\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#----------------------------------------------------------------------------------------------------------------------
#funcion que realiza el bluckget con los datos que solicita del usuario
funcionA(){
	clear
	echo "+________________________________________________________________________________________+"
	echo
	echo "///////////////////////////////// PETICION BULKGET //////////////////////////////////////"
	echo "+________________________________________________________________________________________+"
	echo
	echo -n -e "  => Ingresar el numero de escalares: "
	read numEsc
	echo -n -e "\n  => Ingresar el numero de repeticiones: "
	read numRep
	echo -n -e "\n  => Ingresar los objetos MIB escalares (separados por espacios ejem: sysName sysDescr): "
	read mibEsc
	echo -n -e "\n  => Ingresar los objetos MIB no escalares (separados por espacios ejem: ifSpeed ifTable): "
	read mibNoEsc
	#construccion del comando snmpbulkget
	echo "Comando ejecutado: snmpbulkget -v 2c -Cn$numEsc -Cr$numRep -c REDESTIC $ip $mibEsc $mibNoEsc"
	echo
	#ejecutar el comando
	snmpbulkget -v 2c -Cn$numEsc -Cr$numRep -c REDESTIC $ip $mibEsc $mibNoEsc
}
funcionB(){
			clear
			echo "+________________________________________________________________________________________+"
			echo
			echo "///////////////////////////// CARACTERISTICAS NODO //////////////////////////////////////"
			echo "+________________________________________________________________________________________+"
			echo
			echo -n -e "Ingrese el nombre del objeto MIB a consultar (ejem: sysName.0 ifSpeed o con el OID .1.3.6.1.2.1.2.2.1.5.1): "
			read nodoM
			echo "Nota: en caso de no visualizar todo el resultado, se debe hacer scroll up a la consola para observar los resultados superiores!!! (Esperar que termine el delay)"
			sleep 4
			#En base a lo ingreso por el usuario, si ingresa un OID .1. a .9. lo identifica como numerico
			aux=".[0-9].*"
			#si ingresa como valor numerico entra en este condicional
			if [[ $nodoM == $aux ]]
			then
				#con snmpwal se consulta la MIB con los datos ingresados y se redirecciona a la salida estandar archivo snmpwalk
				snmpwalk -v 2c -c REDESTIC $ip $nodoM > snmpwalk.txt	
			else
				#se hace un snmptranslate para obtener el OID del MIB
				oidNumber=$(snmptranslate -On -IR $nodoM)
				#se se consulta la MIB con los datos ingresados y se redirecciona a la salida estandar archivo snmpwalk
				snmpwalk -v 2c -c REDESTIC $ip $oidNumber > snmpwalk.txt	
			fi
#--------------------------------------------------------------------------------------------------------------------------
#Del resultado obtenido se debe conocer si el resultado corresponde a un escalar o un MIB no escalar, esto se lo realiza
#conociendo el numero de lineas obtenidas del comando snmpwalk a traves del archivo snmpwalk.txt, en caso de ser escalar
#unicamente se presentaria 1 linea, pero si es no escalar obviamente abra mas de 1 linea en la salida. Se emplea wc con 
#el parametro -l para contar el numero de lineas y se redirige la entrada estandar con <, entrada el archivo de txt.
	numLineas=$(wc -l < snmpwalk.txt)
#Condicional para verificar si se obtiene una unica linea como resultado
	if [ "$numLineas" == "1" ]
	then
		echo "+___________________________________________________________________________________________+" > info.txt
		echo >> info.txt
		echo "La informacion obtenida del nodo $nodoM es la siguiente:" >> info.txt
		echo >> info.txt
		echo " => **** ESCALAR ****" >> info.txt
		echo >> info.txt
#Mediante una pipe se aplica un cut indicando el separador " " y el numero de fila correspondiente a los datos de interes
#-------------------------------------------------------------------------------------------------------------------------
		nombreObjeto=$(cat snmpwalk.txt | cut -d " " -f 1 | cut -d ":" -f 3)
		nombreTipo=$(cat snmpwalk.txt | cut -d " " -f 3 | sed 's/.$//g')
		permiso=$(snmptranslate -Td -IR $nombreObjeto | grep MAX-ACCESS | awk -F ' ' '{print $2}')
		indice=$(cat snmpwalk.txt | cut -d " " -f 1 | cut -d "." -f 2)
#-------------------------------------------------------------------------------------------------------------------------
#Caso para los no escalares
	else
		echo "+___________________________________________________________________________________________+" > info.txt
		echo >> info.txt
		echo "La informacion obtenida del nodo $nodoM es la siguiente:" >> info.txt 
		echo "=> **** NO ESCALAR ****" >> info.txt
		echo >> info.txt
#-------------------------------------------------------------------------------------------------------------------------
		nombreObjeto=$(cat snmpwalk.txt | cut -d " " -f 1 | cut -d ":" -f 3)
		nombreTipo=$(cat snmpwalk.txt | cut -d " " -f 3 | sed 's/.$//g')
		permiso=$(snmptranslate -Td -IR $nombreObjeto | grep MAX-ACCESS | awk -F ' ' '{print $2}')
		indice=$(cat snmpwalk.txt | cut -d " " -f 1 | cut -d "." -f 2)
#-------------------------------------------------------------------------------------------------------------------------
	fi
#-------------------------------------------------------------------------------------------------------------------------
			echo " => Nombres del/los objetos MIB: " >> info.txt
			echo >> info.txt
			echo $nombreObjeto >> info.txt
			echo >> info.txt
			echo " => Indice/indices objeto: " >> info.txt
			echo >> info.txt
			echo $indice >> info.txt
			echo >> info.txt
			echo " => Tipo de dato: " >> info.txt
			echo >> info.txt
			snmptranslate -Td -IR $nombreObjeto | grep "SYNTAX" >> info.txt
			echo >> info.txt
			echo " => Su OID numerica es: " >> info.txt
			echo >> info.txt
			snmptranslate -On -IR $nombreObjeto  >> info.txt
			echo >> info.txt
			echo " => Su OID textual es: " >> info.txt
			echo >> info.txt
			snmptranslate -Onf -IR $nombreObjeto  >> info.txt	 		
			echo >> info.txt
			echo " => Persmisos: " >> info.txt
			echo >> info.txt
			echo $permiso>> info.txt		
			echo >> info.txt
			echo "+___________________________________________________________________________________________+"
			clear
			cat info.txt
			echo "+___________________________________________________________________________________________+" 
			echo
}

menu(){
	echo "+________________________________________________________________________________________+"
	echo
	echo "//////////////////////////////////////// MENU ///////////////////////////////////////////"
	echo "+________________________________________________________________________________________+"
	echo -n -e "a) Obtener información de nodos MIB \n"
	echo -n -e "b) Características de un objeto MIB. \n"
	echo -n -e "c) Salir\n"
	echo -n -e "Ingrese una opcion: "
	read op
#Llamada a funciones dependiendo de lo que el usuario elija
	case $op in 
		a)
			funcionA
		;;
		b)
			funcionB
		;;
		c)
			echo
			echo "SALIENDO...."
			echo
			echo "+________________________________________________________________________________________+"
			echo
			echo "/////////////////////////////////////////FIN/////////////////////////////////////////////"
			echo "+________________________________________________________________________________________+"
			exit
		;;
	esac

}
#----------------------------------------------------------------------------------------------------------------------
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\WHILE INFINITO DEL PROGRAMA\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#----------------------------------------------------------------------------------------------------------------------
while [ 1=1 ]
do
	menu
done
#----------------------------------------------------------------------------------------------------------------------
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\FIN\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#----------------------------------------------------------------------------------------------------------------------