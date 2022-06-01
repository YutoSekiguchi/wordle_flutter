import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:uuid/uuid.dart';

// 解答の結果はcharとpositionとjudgeが帰ってくるのでそれを格納するためのクラスを用意
class Answer {
  const Answer({
    required this.char,
    required this.position,
    required this.judge,
  });
  final String char;
  final int position;
  final String judge;
}

class WordlePage extends StatelessWidget {
  const WordlePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wordle"),
      ),
      body: const CorrectWord(),
    );
  }
}

final _httpLink = HttpLink("https://serene-garden-89220.herokuapp.com/query");
// Graphql のクライアントを準備
final GraphQLClient client =
    GraphQLClient(link: _httpLink, cache: GraphQLCache());

class CorrectWord extends StatefulWidget {
  const CorrectWord({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CorrectWordState();
}

class CorrectWordState extends State<CorrectWord> {
  final String userId = "kunokuno";

  String word = "";
  String mean ="";
  bool loading = false;
  String wordId = "";
  String answerWord = "";
  List answerResult = [];

  void answer() async {
    setState(() {
      answerResult = [];
    });
    const String answerWordQuery = r'''
mutation answerWordMutation($wordId: String!, $word: String!, $userId: String!) {
  answerWord(wordId: $wordId, word: $word, userId: $userId) {
    chars {
      position
      char
      judge
    }
  }
}
''';
    final MutationOptions options = MutationOptions(
      document: gql(answerWordQuery),
      variables: <String, dynamic>{
        'wordId': wordId,
        'word': answerWord,
        'userId': userId
      },
    );

    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      debugPrint("エラーだった：" + result.exception.toString());
    }

    final data = result.data;
    if (data != null) {
      final answerWord = data["answerWord"];
      // charsはリストで帰ってくるのでListとしてanswerに格納
      final answer = answerWord["chars"] as List;
      // answerの中身を全て見ていく
      setState(() {
        for (var a in answer) {
          answerResult.add(
            Answer(
              char: a["char"],
              position: a["position"],
              judge: a["judge"],
            ),
          );
        }
      });
    }
    debugPrint(wordId);
    debugPrint(answerWord);
    debugPrint(result.toString());
  }

  void getWord() async {
    const uuid = Uuid();
    setState(() {
      wordId = uuid.v4();
    });
    debugPrint(wordId);
    const String getCorrectWordQuery = r'''
query correctWordQuery($wordId: String!) {
  correctWord(wordId: $wordId) {
    word
    mean
  }
}
''';

    final QueryOptions options = QueryOptions(
      document: gql(getCorrectWordQuery),
      variables: <String, dynamic>{
        'wordId': wordId,
      },
    );

    final QueryResult result = await client.query(options);

    if (result.hasException) {
      debugPrint("エラーだった：" + result.exception.toString());
    }

    final data = result.data;

    if (data != null) {
      final correctWord = data["correctWord"];
      setState(() {
        word = correctWord["word"];
        mean = correctWord["mean"];
      });
    }

    debugPrint(result.toString());

    //データが格納されてたらloadingは終わりなのでfalseに
    setState(() {
      loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            const Text(
              "loading...",
              style: TextStyle(color: Colors.pink),
            ),
          ],
          TextButton(
            onPressed: () {
              setState(() {
                loading = true;
              });
              getWord();
            },
            child: const Text(
              "4文字の単語",
              style: TextStyle(color: Colors.white),
            ),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.pink),
            ),
          ),
          Text(word),
          Text(mean),
          TextField(
            onChanged: (value) {
              setState(() {
                answerWord = value;
              });
            },
          ),
          TextButton(
            onPressed: () {
              answer();
            },
            child: const Text(
              "回答する",
              style: TextStyle(color: Colors.white),
            ),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.pink),
            ),
          ),
          if (answerResult.isNotEmpty) ...[
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      answerResult[0].char,
                      style: const TextStyle(fontSize: 90),
                    ),
                    Text(answerResult[0].judge),
                  ],
                ),
                // Spacer() は平等に間隔を空けてくれるものです！
                const Spacer(),
                Column(
                  children: [
                    Text(
                      answerResult[1].char,
                      style: const TextStyle(fontSize: 90),
                    ),
                    Text(answerResult[1].judge),
                  ],
                ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      answerResult[2].char,
                      style: const TextStyle(fontSize: 90),
                    ),
                    Text(answerResult[2].judge),
                  ],
                ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      answerResult[3].char,
                      style: const TextStyle(fontSize: 90),
                    ),
                    Text(answerResult[3].judge),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}