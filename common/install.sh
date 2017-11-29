#!/bin/bash

TOMCAT_HOME=/opt/tomcat
DATA_PATH=/data

init() {
    BASE_URL=$1
    DB_USER=$2
    DB_PASSWORD=$3
    MANAGER_USER=$4
    MANAGER_PASSWORD=$5
    SUPER_USER_PASSWORD=$6
    
    mkdir -p $DATA_PATH

    [ ! -f mysql-connector-java-5.1.42.jar ] && wget -nv -O mysql-connector-java-5.1.42.jar $BASE_URL/common/db_driver/mysql-connector-java-5.1.42.jar
    [ ! -f installer.jar ] && wget -nv -O installer.jar https://www.jahia.com/downloads/jahia/digitalexperiencemanager7.2.1/DigitalExperienceManager-EnterpriseDistribution-7.2.1.1-r56757.4188.jar
    
    wget -nv -O config.xml $BASE_URL/common/dx_7211_processing_withoutTomcat.xml
    sed -i "s#\${DB_USER}#$DB_USER#g" config.xml
    sed -i "s#\${DB_PASSWORD}#$DB_PASSWORD#g" config.xml
    sed -i "s#\${MANAGER_USER}#$MANAGER_USER#g" config.xml
    sed -i "s#\${MANAGER_PASSWORD}#$MANAGER_PASSWORD#g" config.xml
    sed -i "s#\${SUPER_USER_PASSWORD}#$SUPER_USER_PASSWORD#g" config.xml
    FACTORY_DATA=$DATA_PATH
    sed -i "s#\${FACTORY_DATA}#$FACTORY_DATA#g" config.xml
    
    cp config.xml processing-config.xml
    FACTORY_CONFIG=$DATA_PATH/jahia/processing
    sed -i "s#\${INSTALL_PATH}#$FACTORY_CONFIG#g" processing-config.xml
    sed -i "s#\${CREATE_TABLE}#true#g" processing-config.xml
    sed -i "s#\${PROCESSING_SERVER}#true#g" processing-config.xml
    sed -i "s#\${FACTORY_CONFIG}#$FACTORY_CONFIG#g" processing-config.xml
    java -jar installer.jar processing-config.xml
    
    cp config.xml browsing-config.xml
    FACTORY_CONFIG=$DATA_PATH/jahia/browsing
    sed -i "s#\${INSTALL_PATH}#$FACTORY_CONFIG#g" browsing-config.xml
    sed -i "s#\${CREATE_TABLE}#false#g" browsing-config.xml
    sed -i "s#\${PROCESSING_SERVER}#false#g" browsing-config.xml
    sed -i "s#\${FACTORY_CONFIG}#$FACTORY_CONFIG#g" browsing-config.xml
    java -jar installer.jar browsing-config.xml
    
    chown -R tomcat:tomcat $DATA_PATH

    #rm -rf mysql-connector-java-5.1.42.jar
    #rm -rf installer.jar
    #rm -rf config.xml
    #rm -rf $DATA_PATH/jahia
}

setup() {
    MOUNT=$DATA_PATH
    
    if [ "$1" == "browsing" ]
    then  
        MOUNT=/master/$DATA_PATH
        #mkdir -p $DATA_PATH
        cp -rf $MOUNT/digital-factory-data $DATA_PATH
        chown -R tomcat:tomcat $DATA_PATH
    fi
        
    rm -rf $TOMCAT_HOME/webapps/ROOT
    cp -rf $MOUNT/jahia/$1/tomcat/* $TOMCAT_HOME
    
    cp -rf $MOUNT/jahia/$1/digital-factory-config $TOMCAT_HOME/conf
    chown -R tomcat:tomcat $TOMCAT_HOME/conf/digital-factory-config
    sed -i "s#common.loader=\"\\\$#common.loader=\"$TOMCAT_HOME/conf/digital-factory-config\",\"\$#g" $TOMCAT_HOME/conf/catalina.properties
}

reindex() {
    PROP=$TOMCAT_HOME/conf/digital-factory-config/jahia/jahia.properties
    sed -i "s/.*jahia\.jackrabbit\.reindexOnStartup = .*/jahia\.jackrabbit\.reindexOnStartup = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.consistencyCheck = .*/jahia\.jackrabbit\.consistencyCheck = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.consistencyFix = .*/jahia\.jackrabbit\.consistencyFix = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.searchIndex\.enableConsistencyCheck = .*/jahia\.jackrabbit\.searchIndex\.enableConsistencyCheck = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.searchIndex\.autoRepair = .*/jahia\.jackrabbit\.searchIndex\.autoRepair = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.searchIndex\.forceConsistencyCheck = .*/jahia\.jackrabbit\.searchIndex\.forceConsistencyCheck = $1/g" $PROP
}


reindexrm() {
    rm -R $DATA_PATH/digital-factory-data/repository/index
    PROP=$TOMCAT_HOME/conf/digital-factory-config/jahia/jahia.properties
    sed -i "s/.*jahia\.jackrabbit\.reindexOnStartup = .*/jahia\.jackrabbit\.reindexOnStartup = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.consistencyCheck = .*/jahia\.jackrabbit\.consistencyCheck = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.consistencyFix = .*/jahia\.jackrabbit\.consistencyFix = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.searchIndex\.enableConsistencyCheck = .*/jahia\.jackrabbit\.searchIndex\.enableConsistencyCheck = $1/g" $PROP
     sed -i "s/.*jahia\.jackrabbit\.searchIndex\.autoRepair = .*/jahia\.jackrabbit\.searchIndex\.autoRepair = $1/g" $PROP
    sed -i "s/.*jahia\.jackrabbit\.searchIndex\.forceConsistencyCheck = .*/jahia\.jackrabbit\.searchIndex\.forceConsistencyCheck = $1/g" $PROP
}
case $1 in
    init)
        init $2 $3 $4 $5 $6 $7
        ;;
    setupProcessing)
        setup processing
        ;;
    setupBrowsing)
        setup browsing
        ;;
    reindex)
        reindex $2
        ;;
    reindexrm)
        reindexrm $2
        ;;
esac

