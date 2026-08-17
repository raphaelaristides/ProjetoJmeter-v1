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

        }

        stage('Configurar cenário') {
            steps {
                script {
                    switch (params.SCENARIO) {

                        case 'baseline-3':
                            env.USERS = '3'
                            env.RAMPUP = '30'
                            env.DURATION = '180'
                            break

                        case 'load-10':
                            env.USERS = '10'
                            env.RAMPUP = '60'
                            env.DURATION = '300'
                            break

                        case 'load-20':
                            env.USERS = '20'
                            env.RAMPUP = '60'
                            env.DURATION = '300'
                            break

                        case 'load-50':
                            env.USERS = '50'
                            env.RAMPUP = '120'
                            env.DURATION = '600'
                            break

                        default:
                            error "Cenário inválido: ${params.SCENARIO}"
                    }

                    env.RESULT_NAME = "${params.SCENARIO}-${env.BUILD_NUMBER}"

                    echo "Cenário: ${params.SCENARIO}"
                    echo "Usuários: ${env.USERS}"
                    echo "Ramp-up: ${env.RAMPUP}s"
                    echo "Duração: ${env.DURATION}s"
                }
            }
        }

        stage('Validar JMeter') {
            steps {
                bat '"%JMETER_HOME%\\bin\\jmeter.bat" -v'
            }
        }

        stage('Preparar diretórios') {
            steps {
                bat '''
                    if not exist results mkdir results
                    if not exist reports mkdir reports

                    if exist "results\\%RESULT_NAME%.jtl" del /f /q "results\\%RESULT_NAME%.jtl"
                    if exist "reports\\%RESULT_NAME%" rmdir /s /q "reports\\%RESULT_NAME%"
                '''
            }
        }

        stage('Executar JMeter') {
            steps {
                bat '''
                    "%JMETER_HOME%\\bin\\jmeter.bat" -n ^
                    -t "%TEST_PLAN%" ^
                    -Jusers=%USERS% ^
                    -Jrampup=%RAMPUP% ^
                    -Jduration=%DURATION% ^
                    -l "results\\%RESULT_NAME%.jtl" ^
                    -e ^
                    -o "reports\\%RESULT_NAME%"
                '''
            }
        }

        stage('Validar evidências') {
            steps {
                bat '''
                    if not exist "results\\%RESULT_NAME%.jtl" (
                        echo ERRO: arquivo JTL nao foi gerado.
                        exit /b 1
                    )

                    if not exist "reports\\%RESULT_NAME%\\index.html" (
                        echo ERRO: Dashboard HTML nao foi gerado.
                        exit /b 1
                    )

                    echo Evidencias geradas com sucesso.
                '''
            }
        }
		
		stage('Indicadores') {
    steps {
        powershell '''
            & ".\\scripts\\Indicadores.ps1" `
                -JtlFile "results\\$env:RESULT_NAME.jtl" `
                -MaxErrorRate 1 `
                -TR02P95MaxMs 2000 `
                -TR03P95MaxMs 2000 `
                -TR04P95MaxMs 2000 `
                -TR05P95MaxMs 100

            if ($LASTEXITCODE -ne 0) {
                exit $LASTEXITCODE
            }
        '''
    }
}
		
    }

    post {

    always {

        archiveArtifacts(
            artifacts: 'results/**/*.jtl, reports/**/*',
            fingerprint: true,
            allowEmptyArchive: true
        )
    }

    success {
        echo 'Performance Indicadores aprovado.'
    }

    failure {
        echo 'Performance Indicadores reprovado ou ocorreu falha tecnica.'
    }
}
}