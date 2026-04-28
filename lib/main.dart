import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auxiliar/constantes/wt3k.dart';
import 'auxiliar/tratar_peso.dart';

//https://pub.dev/packages/flutter_blue

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      color: Colors.lightBlue,
      home: DeviceScreen(),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _ipController = TextEditingController(text: '192.168.0.1');
  final _portaCtrl = TextEditingController(text: '23');

  final TratarPeso _tratarPeso = TratarPeso();

  ///Buffer para armazenar os dados recebidos do WT3000-IR
  final _buffer = List.filled(255, 0);

  var _posicao = 0;
  //Indice do buffer
  final _bateriaNotifier = ValueNotifier<int>(0);

  final _isBrutoNotifier = ValueNotifier<bool>(true);

  final _isEstavelNotifier = ValueNotifier<bool>(true);

  final _unidadeNotifier = ValueNotifier<String>('kg');

  final _campoPesoNotifier = ValueNotifier<String>(TratarPeso.pesoInvalido);

  final _campoTaraNotifier =
      ValueNotifier<String>('Tara: ${TratarPeso.pesoInvalido} kg');

  double _paddingVertical = 0.0;

  double _paddinPadrao = 0.0;

  double _fonteSizePeso = 0.0;

  double _fonteSizeTara = 0.0;

  var statusConexao = StatusConexao.desconectado;

  @override
  void initState() {
    super.initState();
  }

  Socket? _socket;
  @override
  Widget build(BuildContext context) {
    final larguraDaTela = MediaQuery.of(context).size.width;
    final alturaDaTela = MediaQuery.of(context).size.height;
    final paddingHorizontal = larguraDaTela /
        40.0; //Apenas para ajustar os widgets em relação a tamanho da tela.
    _paddingVertical = alturaDaTela / 61.6;
    _paddinPadrao = paddingHorizontal;
    _fonteSizePeso = larguraDaTela / 6.0;
    _fonteSizeTara = larguraDaTela / 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exemplo WT3000-IR WI-FI"),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //Informações do Peso
            Expanded(
              flex: 0,
              child: Container(
                padding: EdgeInsets.only(
                    left: paddingHorizontal, right: paddingHorizontal),
                height: alturaDaTela / 4,
                color: Colors.blue,
                child: Row(
                  //Display com todas as informações de peso
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            //Tara e bateria
                            children: [
                              Container(
                                padding: EdgeInsets.all(_paddinPadrao),
                                //color: Colors.green,
                                child: ValueListenableBuilder(
                                    valueListenable: _campoTaraNotifier,
                                    builder: (BuildContext context,
                                        String campoTara, _) {
                                      return Text(
                                        //Tara
                                        campoTara,
                                        style: TextStyle(
                                          fontSize: _fonteSizeTara, //50
                                        ),
                                      );
                                    }),
                              ),
                              Flexible(
                                fit: FlexFit.tight,
                                flex: 1,
                                child: Container(
                                  padding: EdgeInsets.all(_paddinPadrao),
                                  alignment: Alignment.centerRight,
                                  //color: Colors.red,
                                  child: ValueListenableBuilder(
                                      valueListenable: _bateriaNotifier,
                                      builder: (BuildContext context,
                                          int imagemIndexBateria, _) {
                                        return const SizedBox(
                                          height: 10,
                                        );
                                      }),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                                //Estável, peso e unidade
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    //Estável
                                    alignment: Alignment.bottomCenter,
                                    padding: EdgeInsets.only(
                                        bottom: _paddingVertical * 3,
                                        left: paddingHorizontal),
                                    //color: Colors.blue,
                                    child: ValueListenableBuilder(
                                      valueListenable: _isEstavelNotifier,
                                      builder: (BuildContext context,
                                          bool isEstavel, _) {
                                        if (isEstavel) {
                                          return const Image(
                                              image: AssetImage(
                                                  'images/estavel.png'));
                                        } else {
                                          //tem que retornar algo, então vou retornar uma caixa vazia
                                          return const SizedBox(
                                            height: 10,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  Flexible(
                                    fit: FlexFit.tight,
                                    flex: 1,
                                    child: Container(
                                      //Peso
                                      alignment: Alignment.bottomRight,
                                      padding: EdgeInsets.only(
                                          bottom: _paddingVertical * 2,
                                          right: paddingHorizontal),
                                      //color: Colors.yellow,
                                      child: ValueListenableBuilder(
                                        valueListenable: _campoPesoNotifier,
                                        builder: (BuildContext context,
                                            String campoPeso, _) {
                                          return Text(
                                            //Peso
                                            campoPeso,
                                            style: TextStyle(
                                              fontSize: _fonteSizePeso, //140
                                            ),
                                            textAlign: TextAlign.end,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Container(
                                    //Unidade
                                    alignment: Alignment.bottomCenter,
                                    padding: EdgeInsets.only(
                                        bottom: _paddingVertical * 3,
                                        right: paddingHorizontal),
                                    child: ValueListenableBuilder(
                                      valueListenable: _unidadeNotifier,
                                      builder: (BuildContext context,
                                          String unidade, _) {
                                        return Text(
                                          unidade,
                                          style: TextStyle(
                                            fontSize: _fonteSizeTara, //50
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (statusConexao == StatusConexao.conectado) _botoesTaraZero(),
            const Spacer(
              flex: 2,
            ),
            if (statusConexao == StatusConexao.conectando)
              Container(
                padding: const EdgeInsets.only(bottom: 50.0),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            if (statusConexao == StatusConexao.desconectado) _buildConexao(),
            if (statusConexao == StatusConexao.conectado) _buildDesconexao(),
          ]),
    );
  }

  Future<void> _conectar() async {
    var ip = _ipController.text;
    var porta = int.parse(_portaCtrl.text);

    setState(() {
      statusConexao = StatusConexao.conectando;
    });

    Socket.connect(ip, porta, timeout: const Duration(seconds: 5))
        .then((socket) {
      setState(() {
        statusConexao = StatusConexao.conectado;
      });

      _socket = socket;

      socket.listen(
        (List<int> data) {
          for (var b in data) {
            if (_posicao >= _buffer.length) _posicao = 0;
            _buffer[_posicao++] = b;

            if (_posicao > 1) {
              if ((_buffer[_posicao - 2]) == 13 &&
                  (_buffer[_posicao - 1]) == 10) {
                /*
                  * Quando encontra a sequencia [CR][LF] no buffer, ele envia para a rotina de tratamento.
                  * Essa rotina vai validar e extrair as informações de peso.
                  * Se por exemplo, o buffer não tiver o tamanho esperado (27 no caso do WT3000-I-R), ele é descartado.
                  * */

                if (_tratarPeso.lerW01(_buffer, _posicao)) {
                  /*
                    Modificar os campos ValueNotifiers faz com que os Widgets ValueListenableBuilder associados
                    se modifiquem automaticamente com os novos valores.
                  */

                  _bateriaNotifier.value = 0;
                  _isBrutoNotifier.value = _tratarPeso.isBruto;
                  _isEstavelNotifier.value = _tratarPeso.isEstavel;
                  _unidadeNotifier.value = _tratarPeso.unidade;
                  _campoPesoNotifier.value = _tratarPeso.pesoLiqFormatado;
                  _campoTaraNotifier.value =
                      "Tara: ${_tratarPeso.taraFormatada} ${_tratarPeso.unidade}";
                }

                _posicao = 0;
              }
            }
          }
        },
        onDone: () {
          setState(() {
            statusConexao = StatusConexao.desconectado;
          });
          if (kDebugMode) {
            print("Socket listen onDone. Socket desconectado");
          }
          _campoPesoNotifier.value = TratarPeso.pesoInvalido;
          exibirAlerta(titulo: 'Conexão', mensagem: 'Balança desconectada');
        },
      );
    }).onError((error, stackTrace) async {
      if (kDebugMode) {
        print("Socket connect onError. Não foi possível conectar.\n $error");
      }
      setState(() {
        statusConexao = StatusConexao.desconectado;
      });
      await exibirAlerta(
          titulo: 'Conexão',
          mensagem: 'Não foi possível conectar com a balança.\n $error');
    });
  }

  Future<void> _desconectar() async {
    await _socket?.close();
  }

  Future<void> _tarar() async {
    _enviarComando(Comandos.tarar);
  }

  Future<void> _zerar() async {
    _enviarComando(Comandos.zerar);
  }

  Future<void> _enviarComando(String commandData) async {
    //var buff = commandData.codeUnits;

    try {
      _socket?.write(commandData);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Widget _botoesTaraZero() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ElevatedButton(
            child: Text(
              "Tarar",
              style: TextStyle(fontSize: _fonteSizeTara),
            ),
            onPressed: () {
              _tarar();
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            child: Text(
              "Zerar",
              style: TextStyle(fontSize: _fonteSizeTara),
            ),
            onPressed: () {
              _zerar();
            },
          ),
        ),
      ],
    );
  }

  _buildConexao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      //mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(bottom: 20.0),
          child: const Text(
            'Informe o IP e a porta da balança e toque em conectar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: TextField(
            controller: _ipController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'IP/Host name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: TextField(
            controller: _portaCtrl,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Porta',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _conectar,
          child: Text(
            'Conectar',
            style: TextStyle(fontSize: _fonteSizeTara),
          ),
        ),
      ],
    );
  }

  _buildDesconexao() {
    return ElevatedButton(
      onPressed: _desconectar,
      child: Text(
        'Desconectar',
        style: TextStyle(fontSize: _fonteSizeTara),
      ),
    );
  }

  Future exibirAlerta({required titulo, required mensagem}) async {
    await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: ListTile(
            title: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: const Icon(
              Icons.info_outline,
              color: Colors.red,
            ),
          ),
          content: Text(
            mensagem,
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Ok',
              ),
            ),
          ],
        );
      },
    );
  }
}
