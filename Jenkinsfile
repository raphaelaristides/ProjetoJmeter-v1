pipeline {
    agent any

    triggers {
        pollSCM('H/5 * * * *')
    }

    parameters {
        choice(
            name: 'SCENARIO',
            choices: ['baseline-3', 'load-10', 'load-20', 'load-50'],
            description: 'Selecione o cenário de performance'
        )
    }

    environment {
        JMETER_HOME = 'C:\\apache-jmeter-5.6.3'
        TEST_PLAN   = 'ProjetoCSV.jmx'
    }

    stages {
        // restante da pipeline
    }
}