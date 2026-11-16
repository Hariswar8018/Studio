import 'package:grammar_app/models/grammar_model.dart';
import 'package:grammar_app/models/vocab_model.dart';
import 'package:grammar_app/models/kanji_model.dart';

final List<Map<String, dynamic>> initialSampleGrammarJson = [
  // N3: ように vs ために vs ようにする (Provided by User)
  {
    "id": "grammar_purpose_001",
    "title": "ように vs ために vs ようにする",
    "jlpt": "N3",
    "category": "Purpose and Intention",
    "tags": [
      "purpose",
      "intention",
      "desired-result",
      "similar-grammar",
      "grammar-discrimination"
    ],
    "description": "Practice distinguishing desired outcomes, deliberate purposes, and efforts or habits.",
    "globalOptions": {
      "A": {
        "grammar": "ように",
        "meaning": "So that / In order to",
        "structure": "Verb dictionary/potential/ない form + ように",
        "usage": "Expresses a desired outcome, often involving ability, possibility, or prevention."
      },
      "B": {
        "grammar": "ために",
        "meaning": "In order to / For the purpose of",
        "structure": "Verb dictionary form + ために",
        "usage": "Expresses a deliberate purpose pursued through an intentional action."
      },
      "C": {
        "grammar": "ようにする",
        "meaning": "Make an effort to / Try to",
        "structure": "Verb dictionary/ない form + ようにする",
        "usage": "Expresses conscious effort or forming a habit."
      }
    },
    "instructions": "Choose the most natural grammar expression for each blank. Conjugate the chosen expression when required.",
    "questions": [
      {
        "id": 1,
        "japanese": "日本語が話せる___、毎日練習しています。",
        "english": "I practice every day so that I can speak Japanese.",
        "correctOption": "A",
        "completedSentence": "日本語が話せるように、毎日練習しています。",
        "explanation": {
          "correct": "ように expresses the desired ability to speak Japanese. 話せる is a potential verb.",
          "wrong": {
            "B": "ために is not the natural choice with the potential verb 話せる in this purpose construction.",
            "C": "ようにする would describe an effort to make something happen, rather than directly connecting this desired ability to the daily practice."
          }
        }
      },
      {
        "id": 2,
        "japanese": "日本へ留学する___、お金を貯めています。",
        "english": "I'm saving money in order to study abroad in Japan.",
        "correctOption": "B",
        "completedSentence": "日本へ留学するために、お金を貯めています。",
        "explanation": {
          "correct": "ために expresses the deliberate purpose of saving money: studying abroad.",
          "wrong": {
            "A": "ように is less natural with the directly intentional action 留学する in this construction.",
            "C": "ようにする would emphasize making an effort to study abroad, rather than expressing the straightforward purpose of saving money."
          }
        }
      },
      {
        "id": 3,
        "japanese": "健康のために、毎日野菜を食べる___。",
        "english": "I make an effort to eat vegetables every day for my health.",
        "correctOption": "C",
        "completedSentence": "健康のために、毎日野菜を食べるようにする。",
        "explanation": {
          "correct": "ようにする expresses a conscious effort or habit of eating vegetables.",
          "wrong": {
            "A": "ように alone cannot naturally finish this sentence as an independent main predicate.",
            "B": "ために would introduce a purpose clause and would require an appropriate following main predicate."
          }
        }
      },
      {
        "id": 4,
        "japanese": "忘れない___、メモを取ってください。",
        "english": "Please take notes so that you don't forget.",
        "correctOption": "A",
        "completedSentence": "忘れないように、メモを取ってください。",
        "explanation": {
          "correct": "ように expresses prevention of an unwanted result: forgetting.",
          "wrong": {
            "B": "忘れないために can also be grammatical and natural here. It emphasizes deliberate prevention, so this item is not suitable for a strict single-answer quiz without additional context.",
            "C": "ようにする does not fit naturally before the comma in this sentence without further restructuring."
          }
        },
        "needsRevision": true
      },
      {
        "id": 5,
        "japanese": "新しいパソコンを買う___、アルバイトを始めました。",
        "english": "I started a part-time job in order to buy a new computer.",
        "correctOption": "B",
        "completedSentence": "新しいパソコンを買うために、アルバイトを始めました。",
        "explanation": {
          "correct": "ために connects a deliberate goal, buying a computer, with an intentional action.",
          "wrong": {
            "A": "ように is less natural with the directly controlled action 買う in this construction.",
            "C": "ようにする would describe making an effort to buy a computer rather than directly stating the purpose of taking the job."
          }
        }
      },
      {
        "id": 6,
        "japanese": "最近、夜遅くまで起きない___。",
        "english": "Recently, I've been trying not to stay up late.",
        "correctOption": "C",
        "completedSentence": "最近、夜遅くまで起きないようにする。",
        "explanation": {
          "correct": "ようにする describes a conscious effort to avoid staying up late.",
          "wrong": {
            "A": "ように alone does not complete the main predicate.",
            "B": "ために would introduce a purpose clause and leave the sentence incomplete."
          }
        }
      },
      {
        "id": 7,
        "japanese": "誰でも読める___、漢字にふりがなを付けました。",
        "english": "I added furigana so that anyone could read it.",
        "correctOption": "A",
        "completedSentence": "誰でも読めるように、漢字にふりがなを付けました。",
        "explanation": {
          "correct": "ように expresses the desired ability of anyone to read the text.",
          "wrong": {
            "B": "ために is unnatural with 読める in this construction.",
            "C": "ようにする would focus on an effort to ensure readability rather than directly describing the purpose of adding furigana."
          }
        }
      },
      {
        "id": 8,
        "japanese": "友達に会う___、東京へ行きました。",
        "english": "I went to Tokyo in order to meet my friend.",
        "correctOption": "B",
        "completedSentence": "友達に会うために、東京へ行きました。",
        "explanation": {
          "correct": "ために expresses the deliberate purpose of going to Tokyo.",
          "wrong": {
            "A": "ように is less natural with the intentional action 会う in this straightforward purpose statement.",
            "C": "ようにする would shift the meaning toward making an effort to meet someone."
          }
        }
      },
      {
        "id": 9,
        "japanese": "毎朝、ニュースを確認する___。",
        "english": "I try to check the news every morning.",
        "correctOption": "C",
        "completedSentence": "毎朝、ニュースを確認するようにする。",
        "explanation": {
          "correct": "ようにする expresses an intentional routine or effort.",
          "wrong": {
            "A": "ように alone cannot serve as the main predicate here.",
            "B": "ために introduces a purpose and requires another clause."
          }
        }
      },
      {
        "id": 10,
        "japanese": "後ろの人にも見える___、画面を大きくしました。",
        "english": "I enlarged the screen so people in the back could see.",
        "correctOption": "A",
        "completedSentence": "後ろの人にも見えるように、画面を大きくしました。",
        "explanation": {
          "correct": "ように expresses a desired state of visibility.",
          "wrong": {
            "B": "ために is unnatural with the potential or state verb 見える in this construction.",
            "C": "ようにする changes the construction to one emphasizing an effort to ensure visibility."
          }
        }
      },
      {
        "id": 11,
        "japanese": "医者になる___、医学部で勉強しています。",
        "english": "I'm studying in medical school to become a doctor.",
        "correctOption": "B",
        "completedSentence": "医者になるために、医学部で勉強しています。",
        "explanation": {
          "correct": "ために expresses a deliberate long-term goal.",
          "wrong": {
            "A": "ように is less natural with なる here when expressing a straightforward intentional career goal.",
            "C": "ようにする would emphasize an effort to bring about the goal rather than the purpose of studying."
          }
        }
      },
      {
        "id": 12,
        "japanese": "これからは、もっと丁寧に話す___。",
        "english": "From now on, I'll try to speak more politely.",
        "correctOption": "C",
        "completedSentence": "これからは、もっと丁寧に話すようにする。",
        "explanation": {
          "correct": "ようにする expresses a decision to make a conscious effort.",
          "wrong": {
            "A": "ように alone leaves the main clause incomplete.",
            "B": "ために would express a purpose rather than complete the intended decision."
          }
        }
      },
      {
        "id": 13,
        "japanese": "電車に間に合う___、早く家を出ました。",
        "english": "I left home early so that I could catch the train.",
        "correctOption": "A",
        "completedSentence": "電車に間に合うように、早く家を出ました。",
        "explanation": {
          "correct": "ように emphasizes the desired result of catching the train.",
          "wrong": {
            "B": "間に合うために can also be used in Japanese, so the two expressions are not absolutely exclusive in this context.",
            "C": "ようにする shifts the focus toward making an effort and is less natural here."
          }
        },
        "needsRevision": true
      },
      {
        "id": 14,
        "japanese": "家を建てる___、土地を買いました。",
        "english": "I bought land in order to build a house.",
        "correctOption": "B",
        "completedSentence": "家を建てるために、土地を買いました。",
        "explanation": {
          "correct": "ために states the intentional purpose behind purchasing land.",
          "wrong": {
            "A": "ように is less natural for this direct intentional action.",
            "C": "ようにする changes the focus to an effort to arrange for building a house."
          }
        }
      },
      {
        "id": 15,
        "japanese": "仕事中は、スマホを見ない___。",
        "english": "I try not to look at my phone while working.",
        "correctOption": "C",
        "completedSentence": "仕事中は、スマホを見ないようにする。",
        "explanation": {
          "correct": "ようにする expresses a deliberate effort to avoid a behavior.",
          "wrong": {
            "A": "ように alone does not form a complete predicate.",
            "B": "ために would require an additional main action or clause."
          }
        }
      },
      {
        "id": 16,
        "japanese": "子供にも理解できる___、簡単な言葉を使いました。",
        "english": "I used simple words so that children could understand.",
        "correctOption": "A",
        "completedSentence": "子供にも理解できるように、簡単な言葉を使いました。",
        "explanation": {
          "correct": "ように expresses the desired ability to understand.",
          "wrong": {
            "B": "ために is unnatural directly after the potential verb 理解できる here.",
            "C": "ようにする would introduce an effort-focused construction rather than this direct purpose clause."
          }
        }
      },
      {
        "id": 17,
        "japanese": "日本の文化を研究する___、大学院に入りました。",
        "english": "I entered graduate school to research Japanese culture.",
        "correctOption": "B",
        "completedSentence": "日本の文化を研究するために、大学院に入りました。",
        "explanation": {
          "correct": "ために expresses the deliberate purpose of entering graduate school.",
          "wrong": {
            "A": "ように is less natural with this directly intentional research activity.",
            "C": "ようにする would emphasize making an effort to conduct research."
          }
        }
      },
      {
        "id": 18,
        "japanese": "これから毎日、日記を書く___。",
        "english": "From now on, I'll try to write a diary every day.",
        "correctOption": "C",
        "completedSentence": "これから毎日、日記を書くようにする。",
        "explanation": {
          "correct": "ようにする expresses an effort to develop a habit.",
          "wrong": {
            "A": "ように alone leaves the sentence incomplete.",
            "B": "ために would introduce a purpose without a following action."
          }
        }
      },
      {
        "id": 19,
        "japanese": "みんなが座れる___、椅子を追加しました。",
        "english": "I added chairs so that everyone could sit.",
        "correctOption": "A",
        "completedSentence": "みんなが座れるように、椅子を追加しました。",
        "explanation": {
          "correct": "ように expresses the desired possibility of everyone being able to sit.",
          "wrong": {
            "B": "ために is unnatural with the potential verb 座れる in this construction.",
            "C": "ようにする changes the focus toward making an effort to arrange seating."
          }
        }
      },
      {
        "id": 20,
        "japanese": "新しい車を買う___、節約しています。",
        "english": "I'm saving money in order to buy a new car.",
        "correctOption": "B",
        "completedSentence": "新しい車を買うために、節約しています。",
        "explanation": {
          "correct": "ために expresses the specific purpose of saving money.",
          "wrong": {
            "A": "ように is less natural with the directly intentional verb 買う.",
            "C": "ようにする would emphasize trying to arrange the purchase rather than stating the straightforward purpose."
          }
        }
      },
      {
        "id": 21,
        "japanese": "人の話を最後まで聞く___。",
        "english": "I'll try to listen to people until they finish speaking.",
        "correctOption": "C",
        "completedSentence": "人の話を最後まで聞くようにする。",
        "explanation": {
          "correct": "ようにする expresses a conscious effort to improve behavior.",
          "wrong": {
            "A": "ように alone cannot finish the sentence as a main predicate.",
            "B": "ために requires another clause stating the action taken for that purpose."
          }
        }
      },
      {
        "id": 22,
        "japanese": "誰でも使える___、説明書を簡単にしました。",
        "english": "I simplified the instructions so that anyone could use it.",
        "correctOption": "A",
        "completedSentence": "誰でも使えるように、説明書を簡単にしました。",
        "explanation": {
          "correct": "ように expresses the desired ability for anyone to use something.",
          "wrong": {
            "B": "ために is unnatural with the potential verb 使える in this construction.",
            "C": "ようにする would emphasize an effort to make the product usable rather than directly linking the desired result to the simplified instructions."
          }
        }
      },
      {
        "id": 23,
        "japanese": "海外で働く___、英語を勉強しています。",
        "english": "I'm studying English in order to work abroad.",
        "correctOption": "B",
        "completedSentence": "海外で働くために、英語を勉強しています。",
        "explanation": {
          "correct": "ために expresses a deliberate career goal.",
          "wrong": {
            "A": "ように is less natural with the directly intentional verb 働く in this construction.",
            "C": "ようにする shifts the meaning toward making an effort to work abroad."
          }
        }
      },
      {
        "id": 24,
        "japanese": "大事なことは、すぐにメモする___。",
        "english": "I try to write down important things immediately.",
        "correctOption": "C",
        "completedSentence": "大事なことは、すぐにメモするようにする。",
        "explanation": {
          "correct": "ようにする expresses a conscious effort to form a habit.",
          "wrong": {
            "A": "ように alone cannot complete the sentence.",
            "B": "ために would require another main clause."
          }
        }
      },
      {
        "id": 25,
        "japanese": "遠くからでも見える___、大きな看板を設置しました。",
        "english": "We installed a large sign so that it could be seen from far away.",
        "correctOption": "A",
        "completedSentence": "遠くからでも見えるように、大きな看板を設置しました。",
        "explanation": {
          "correct": "ように expresses the desired state of visibility.",
          "wrong": {
            "B": "ために is unnatural directly after 見える in this purpose construction.",
            "C": "ようにする shifts the construction toward making an effort to ensure visibility."
          }
        }
      }
    ],
    "metadata": {
      "questionCount": 25,
      "optionCount": 3,
      "questionType": "global-options-fill-blank",
      "answerMode": "single-choice",
      "requiresUniqueAnswer": true,
      "version": 1
    }
  },

  // N5: から vs ので (Reason & Cause)
  {
    "id": "grammar_n5_reason_001",
    "title": "から vs ので",
    "jlpt": "N5",
    "category": "Cause and Reason",
    "tags": ["reason", "cause", "politeness", "n5-basics"],
    "description": "Distinguishing subjective/direct reason (から) from polite/objective cause (ので).",
    "globalOptions": {
      "A": {
        "grammar": "から",
        "meaning": "Because / Since (Subjective/Direct)",
        "structure": "Plain/Polite form + から",
        "usage": "Expresses personal reasons, suggestions, commands, or subjective thoughts."
      },
      "B": {
        "grammar": "ので",
        "meaning": "Because / As (Polite/Objective)",
        "structure": "Plain form (な for Na-adj/Noun) + ので",
        "usage": "Mild, polite cause stating natural, objective consequences or polite requests."
      }
    },
    "instructions": "Choose whether から or ので is the most natural match.",
    "questions": [
      {
        "id": 1,
        "japanese": "雨が降っている___、傘を持って行きなさい。",
        "english": "Since it's raining, take an umbrella with you.",
        "correctOption": "A",
        "completedSentence": "雨が降っているから、傘を持って行きなさい。",
        "explanation": {
          "correct": "から is appropriate before strong commands/instructions (〜なさい).",
          "wrong": {
            "B": "ので cannot be naturally followed by imperative commands or strong directives like 〜なさい."
          }
        }
      },
      {
        "id": 2,
        "japanese": "電車が遅れました___、遅刻しました。",
        "english": "Because the train was delayed, I was late.",
        "correctOption": "B",
        "completedSentence": "電車が遅れましたので、遅刻しました。",
        "explanation": {
          "correct": "ので expresses a polite, factual and objective reason to superiors or teachers.",
          "wrong": {
            "A": "から sounds more direct and subjective when offering an excuse."
          }
        }
      },
      {
        "id": 3,
        "japanese": "危ない___、触らないでください。",
        "english": "It's dangerous, so please do not touch it.",
        "correctOption": "A",
        "completedSentence": "危ないから、触らないでください。",
        "explanation": {
          "correct": "から provides the direct subjective caution.",
          "wrong": {
            "B": "ので is softer, but から is the standard direct warning."
          }
        }
      },
      {
        "id": 4,
        "japanese": "明日試験がある___、今夜は早く寝ます。",
        "english": "Since I have an exam tomorrow, I'm going to sleep early tonight.",
        "correctOption": "A",
        "completedSentence": "明日試験があるから、今夜は早く寝ます。",
        "explanation": {
          "correct": "から shows personal decision/volition.",
          "wrong": {
            "B": "ので would sound overly detached/objective for a simple personal daily choice."
          }
        }
      },
      {
        "id": 5,
        "japanese": "静か___、この図書館が好きです。",
        "english": "Because it's quiet, I like this library.",
        "correctOption": "B",
        "completedSentence": "静かなので、この図書館が好きです。",
        "explanation": {
          "correct": "静かなので properly joins with Na-adjective 静か (using な).",
          "wrong": {
            "A": "から requires だ after Na-adjectives in plain form (静かだから)."
          }
        }
      }
    ],
    "metadata": {
      "questionCount": 5,
      "optionCount": 2,
      "questionType": "global-options-fill-blank",
      "answerMode": "single-choice",
      "requiresUniqueAnswer": true,
      "version": 1
    }
  },

  // N4: 〜てみる vs 〜てしまう vs 〜ておく
  {
    "id": "grammar_n4_aux_001",
    "title": "〜てみる vs 〜てしまう vs 〜ておく",
    "jlpt": "N4",
    "category": "Auxiliary Verbs",
    "tags": ["te-form", "auxiliary", "preparation", "regret", "attempt"],
    "description": "Mastering action attempts (てみる), completion/regret (てしまう), and preparation (ておく).",
    "globalOptions": {
      "A": {
        "grammar": "〜てみる",
        "meaning": "Try doing something to see what happens",
        "structure": "Verb て-form + みる",
        "usage": "Carrying out an exploratory action to test or sample the outcome."
      },
      "B": {
        "grammar": "〜てしまう",
        "meaning": "Do completely / Regrettably do by accident",
        "structure": "Verb て-form + しまう",
        "usage": "Total completion of an action, or sorrow/regret over an unintentional mishap."
      },
      "C": {
        "grammar": "〜ておく",
        "meaning": "Do in advance / Preparation",
        "structure": "Verb て-form + おく",
        "usage": "Doing something ahead of time in preparation for future need."
      }
    },
    "instructions": "Select the correct auxiliary verb nuance.",
    "questions": [
      {
        "id": 1,
        "japanese": "旅行の前に、切符を買っ___。",
        "english": "I bought tickets in advance before the trip.",
        "correctOption": "C",
        "completedSentence": "旅行の前に、切符を買っておく。",
        "explanation": {
          "correct": "〜ておく describes doing an action beforehand in preparation for the trip.",
          "wrong": {
            "A": "〜てみる implies casually trying to buy tickets to see what happens.",
            "B": "〜てしまう implies regrettably buying the tickets by mistake."
          }
        }
      },
      {
        "id": 2,
        "japanese": "大切なお皿を割っ___。",
        "english": "I accidentally broke an important plate.",
        "correctOption": "B",
        "completedSentence": "大切なお皿を割ってしまう。",
        "explanation": {
          "correct": "〜てしまう conveys regret/accident over breaking the plate.",
          "wrong": {
            "A": "〜てみる would mean intentionally breaking it to test it out.",
            "C": "〜ておく would mean breaking it in advance for later convenience."
          }
        }
      },
      {
        "id": 3,
        "japanese": "日本の納豆を一口食べ___。",
        "english": "I tried eating a bite of Japanese natto (to see what it tastes like).",
        "correctOption": "A",
        "completedSentence": "日本の納豆を一口食べてみる。",
        "explanation": {
          "correct": "〜てみる is used for trying a food or experience for the first time.",
          "wrong": {
            "B": "〜てしまう would mean eating it with regret or finishing all of it completely.",
            "C": "〜ておく would mean eating it in preparation for future events."
          }
        }
      },
      {
        "id": 4,
        "japanese": "会議の資料を事前に印刷し___。",
        "english": "I printed the meeting handouts in advance.",
        "correctOption": "C",
        "completedSentence": "会議の資料を事前に印刷しておく。",
        "explanation": {
          "correct": "印刷しておく prepares materials before the meeting.",
          "wrong": {
            "A": "印刷してみる means printing as a test to see.",
            "B": "印刷してしまう implies an accidental printing error."
          }
        }
      },
      {
        "id": 5,
        "japanese": "うっかり財布を忘れ___。",
        "english": "I carelessly forgot my wallet.",
        "correctOption": "B",
        "completedSentence": "うっかり財布を忘れてしまう。",
        "explanation": {
          "correct": "忘れてしまう paired with うっかり conveys an unfortunate accident.",
          "wrong": {
            "A": "忘れてみる would mean attempting to forget.",
            "C": "忘れておく would mean deliberately forgetting in advance."
          }
        }
      }
    ],
    "metadata": {
      "questionCount": 5,
      "optionCount": 3,
      "questionType": "global-options-fill-blank",
      "answerMode": "single-choice",
      "requiresUniqueAnswer": true,
      "version": 1
    }
  },

  // N2: わけがない vs はずがない vs わけではない
  {
    "id": "grammar_n2_wake_001",
    "title": "わけがない vs わけではない",
    "jlpt": "N2",
    "category": "Negation and Reasoning",
    "tags": ["wake", "partial-negation", "strong-negation", "n2-reasoning"],
    "description": "Distinguishing impossible reasoning (わけがない) from partial negation (わけではない).",
    "globalOptions": {
      "A": {
        "grammar": "わけがない",
        "meaning": "There is no way that / Impossible that",
        "structure": "Plain form + わけがない",
        "usage": "Strong logical denial that something could possibly be true."
      },
      "B": {
        "grammar": "わけではない",
        "meaning": "It doesn't mean that / Not necessarily",
        "structure": "Plain form + わけではない",
        "usage": "Partial negation; softens a broad assumption or clarifies that it's not entirely the case."
      }
    },
    "instructions": "Distinguish between absolute impossibility and partial negation.",
    "questions": [
      {
        "id": 1,
        "japanese": "あんなに練習したんだから、負ける___。",
        "english": "Since we practiced that hard, there's no way we could lose.",
        "correctOption": "A",
        "completedSentence": "あんなに練習したんだから、負けるわけがない。",
        "explanation": {
          "correct": "わけがない expresses strong conviction of impossibility based on logical reason.",
          "wrong": {
            "B": "わけではない would merely say 'it doesn't mean we will lose', which is too weak here."
          }
        }
      },
      {
        "id": 2,
        "japanese": "日本料理が嫌いな___が、刺身は苦手です。",
        "english": "It's not that I dislike Japanese food, but I'm not good with sashimi.",
        "correctOption": "B",
        "completedSentence": "日本料理が嫌いなわけではないが、刺身は苦手です。",
        "explanation": {
          "correct": "わけではない provides partial negation: 'not that I hate all Japanese food'.",
          "wrong": {
            "A": "わけがない would mean 'there is zero possibility I dislike Japanese food', clashing with the contrastive が."
          }
        }
      },
      {
        "id": 3,
        "japanese": "彼がそんな嘘をつく___。",
        "english": "There's no way that he would tell such a lie.",
        "correctOption": "A",
        "completedSentence": "彼がそんな嘘をつくわけがない。",
        "explanation": {
          "correct": "わけがない strongly denies the moral or behavioral possibility of him lying.",
          "wrong": {
            "B": "わけではない would mean 'it does not mean that he lies', leaving the statement weak."
          }
        }
      },
      {
        "id": 4,
        "japanese": "お金があれば幸せになれるという___。",
        "english": "Having money does not necessarily mean one will become happy.",
        "correctOption": "B",
        "completedSentence": "お金があれば幸せになれるというわけではない。",
        "explanation": {
          "correct": "〜というわけではない is the standard idiom for 'does not necessarily mean that'.",
          "wrong": {
            "A": "わけがない would assert that rich people can never be happy, which is absurd."
          }
        }
      },
      {
        "id": 5,
        "japanese": "初心者の一人だけでできる___。",
        "english": "There's no way a complete beginner can do it alone.",
        "correctOption": "A",
        "completedSentence": "初心者の一人だけでできるわけがない。",
        "explanation": {
          "correct": "わけがない points out the sheer logical impossibility for a solo novice.",
          "wrong": {
            "B": "わけではない fails to convey the required strong impossibility."
          }
        }
      }
    ],
    "metadata": {
      "questionCount": 5,
      "optionCount": 2,
      "questionType": "global-options-fill-blank",
      "answerMode": "single-choice",
      "requiresUniqueAnswer": true,
      "version": 1
    }
  },

  // N1: 〜であれ vs 〜とあれば vs 〜すら
  {
    "id": "grammar_n1_formal_001",
    "title": "〜であれ vs 〜とあれば",
    "jlpt": "N1",
    "category": "High Level Conditionals",
    "tags": ["n1-grammar", "formal", "literary", "conditionals"],
    "description": "Distinguishing hypothetical concessions (であれ) from motivated conditional commitment (とあれば).",
    "globalOptions": {
      "A": {
        "grammar": "〜であれ",
        "meaning": "Even if / Whether it be / Regardless of",
        "structure": "Noun / な-adj + であれ",
        "usage": "Formal written concession indicating that the circumstance makes no difference."
      },
      "B": {
        "grammar": "〜とあれば",
        "meaning": "If it is for the sake of / Given the special condition",
        "structure": "Plain form / Noun + とあれば",
        "usage": "Indicates that under this particular special circumstance, one is willing to do anything."
      }
    },
    "instructions": "Distinguish between universal concession and special conditional determination.",
    "questions": [
      {
        "id": 1,
        "japanese": "子供の将来の___、どんな苦労もいとわない。",
        "english": "If it is for my child's future, I will spare no hardship.",
        "correctOption": "B",
        "completedSentence": "子供の将来のためとあれば、どんな苦労もいとわない。",
        "explanation": {
          "correct": "とあれば expresses extreme determination given a special reason (the child's future).",
          "wrong": {
            "A": "であれ expresses 'regardless of', which does not fit the motivated sacrifice clause."
          }
        }
      },
      {
        "id": 2,
        "japanese": "理由が何___、暴力は決して許されない。",
        "english": "Whatever the reason may be, violence is never permitted.",
        "correctOption": "A",
        "completedSentence": "理由が何であれ、暴力は決して許されない。",
        "explanation": {
          "correct": "何であれ means 'regardless of what it is'.",
          "wrong": {
            "B": "とあれば would imply willingness to act if a reason exists, which is contrary to the ban."
          }
        }
      },
      {
        "id": 3,
        "japanese": "君の頼み___、断るわけにはいかない。",
        "english": "If it is a request from you, I cannot possibly refuse.",
        "correctOption": "B",
        "completedSentence": "君の頼みとあれば、断るわけにはいかない。",
        "explanation": {
          "correct": "とあれば shows that this special condition (your request) triggers the action.",
          "wrong": {
            "A": "であれ would imply 'even if it is your request', contradicting the affirmative willingness."
          }
        }
      },
      {
        "id": 4,
        "japanese": "いかに困難___、最後までやり遂げる覚悟だ。",
        "english": "No matter how difficult it may be, I am resolved to see it through to the end.",
        "correctOption": "A",
        "completedSentence": "いかに困難であれ、最後までやり遂げる覚悟だ。",
        "explanation": {
          "correct": "いかに〜であれ is a formal written concession meaning 'no matter how difficult'.",
          "wrong": {
            "B": "とあれば cannot collocate with 'いかに' in this concession structure."
          }
        }
      },
      {
        "id": 5,
        "japanese": "平和を取り戻す___、いかなる交渉にも応じる所存です。",
        "english": "If it is to restore peace, we are ready to engage in any negotiation.",
        "correctOption": "B",
        "completedSentence": "平和を取り戻すためとあれば、いかなる交渉にも応じる所存です。",
        "explanation": {
          "correct": "とあれば emphasizes the high determination for a critical goal.",
          "wrong": {
            "A": "であれ fails to link the specific motivation with the proactive resolve."
          }
        }
      }
    ],
    "metadata": {
      "questionCount": 5,
      "optionCount": 2,
      "questionType": "global-options-fill-blank",
      "answerMode": "single-choice",
      "requiresUniqueAnswer": true,
      "version": 1
    }
  }
];

class SampleGrammarData {
  static Map<String, dynamic> getSampleN3Purpose() => initialSampleGrammarJson.first;

  static Map<String, dynamic> getSampleN2NoRelationship() => {
    "id": "n2_no_relationship_001",
    "title": "No Relationship",
    "jlpt": "N2",
    "section": "Grammar",
    "tags": [
      "no-relationship",
      "regardless",
      "indifference",
      "ignoring",
      "priority",
      "contrast"
    ],
    "grammarPoints": [
      {
        "id": "wo_towazu",
        "grammar": "〜を問わず",
        "meaning": "Regardless of",
        "structure": "Noun + を問わず",
        "explanation": "Used when categories or distinctions do not matter."
      },
      {
        "id": "ni_kakawarazu",
        "grammar": "〜にかかわらず",
        "meaning": "Regardless of conditions",
        "structure": "Noun / contrasting expressions + にかかわらず",
        "explanation": "Used when a condition does not affect the outcome."
      },
      {
        "id": "mo_kamawazu",
        "grammar": "〜もかまわず",
        "meaning": "Without caring about",
        "structure": "Noun / plain-form clause + の + もかまわず",
        "explanation": "Used when someone ignores a situation or consequence."
      },
      {
        "id": "wa_tomokaku",
        "grammar": "〜はともかく",
        "meaning": "Leaving aside",
        "structure": "Noun + はともかく",
        "explanation": "Sets one matter aside to emphasize another."
      },
      {
        "id": "wa_sateoki",
        "grammar": "〜はさておき",
        "meaning": "Putting aside for now",
        "structure": "Noun + はさておき",
        "explanation": "Temporarily puts a topic aside to focus on something more important."
      }
    ],
    "globalOptions": {
      "A": "を問わず",
      "B": "にかかわらず",
      "C": "もかまわず",
      "D": "はともかく",
      "E": "はさておき"
    },
    "questions": [
      {
        "id": 1,
        "type": "globalGrammar",
        "grammarId": "wo_towazu",
        "japanese": "この大会は、年齢___、誰でも参加できます。",
        "english": "Anyone can participate in this tournament regardless of age.",
        "correctOption": "A",
        "completedSentence": "この大会は、年齢を問わず、誰でも参加できます。",
        "explanation": {
          "correct": "を問わず expresses no distinction based on age.",
          "wrong": {
            "B": "にかかわらず is also grammatically natural here, so this question should be revised before use as a single-answer item.",
            "C": "もかまわず expresses disregard rather than neutral eligibility.",
            "D": "はともかく would set age aside and emphasize another issue.",
            "E": "はさておき would temporarily put age aside."
          }
        },
        "needsRevision": true
      },
      {
        "id": 2,
        "type": "localVocabulary",
        "grammarId": "wo_towazu",
        "japanese": "この仕事は、___を問わず、誰でも応募できます。",
        "english": "Anyone can apply for this job regardless of educational background.",
        "options": {
          "A": "学歴",
          "B": "天気",
          "C": "気温",
          "D": "速度"
        },
        "correctOption": "A",
        "completedSentence": "この仕事は、学歴を問わず、誰でも応募できます。",
        "explanation": {
          "correct": "学歴 means educational background and is a natural category used in job eligibility.",
          "wrong": {
            "B": "天気 means weather, which is not the intended hiring criterion.",
            "C": "気温 means temperature, which does not match the employment context.",
            "D": "速度 means speed, which is unrelated to the stated hiring condition."
          }
        }
      },
      {
        "id": 3,
        "type": "globalGrammar",
        "grammarId": "ni_kakawarazu",
        "japanese": "参加するかしないか___、明日までに返事をしてください。",
        "english": "Please reply by tomorrow whether you participate or not.",
        "correctOption": "B",
        "completedSentence": "参加するかしないかにかかわらず、明日までに返事をしてください。",
        "explanation": {
          "correct": "にかかわらず naturally follows the contrasting verbal choices.",
          "wrong": {
            "A": "を問わず requires a different noun-based structure.",
            "C": "もかまわず expresses disregarding something.",
            "D": "はともかく does not naturally attach to this contrasting clause.",
            "E": "はさておき is used to set a topic aside rather than express a rule applying to both choices."
          }
        }
      },
      {
        "id": 4,
        "type": "localVocabulary",
        "grammarId": "mo_kamawazu",
        "japanese": "彼は周囲の___もかまわず、大声で歌い始めた。",
        "english": "He started singing loudly without caring about the people watching him.",
        "options": {
          "A": "視線",
          "B": "予定",
          "C": "料金",
          "D": "年齢"
        },
        "correctOption": "A",
        "completedSentence": "彼は周囲の視線もかまわず、大声で歌い始めた。",
        "explanation": {
          "correct": "視線 means gaze or looks, and 周囲の視線もかまわず is a natural expression.",
          "wrong": {
            "B": "予定 means schedule and does not match the context of being watched.",
            "C": "料金 means fee and does not match the situation.",
            "D": "年齢 means age and does not express the intended concern about observers."
          }
        }
      }
    ],
    "metadata": {
      "totalQuestions": 60,
      "questionTypes": [
        "globalGrammar",
        "localVocabulary"
      ],
      "version": 2
    }
  };

  static List<GrammarTopicModel> getInitialSampleGrammarTopics() {
    final list = initialSampleGrammarJson
        .map((json) => GrammarTopicModel.fromMap(json))
        .toList();
    // Also include the unified structure N2 topic
    list.removeWhere((t) => t.id == 'n2_no_relationship_001');
    list.add(GrammarTopicModel.fromMap(getSampleN2NoRelationship()));
    return list;
  }

  static Map<String, dynamic> getSampleN2VocabUsage() => {
    "id": "n2_vocab_usage_001",
    "title": "Vocabulary Usage",
    "jlpt": "N2",
    "section": "Vocabulary",
    "tags": [
      "usage",
      "context",
      "collocation",
      "sentence-completion"
    ],
    "vocabulary": [
      {
        "id": "sokushin",
        "word": "促進",
        "reading": "そくしん",
        "meaning": "Promotion; acceleration; facilitation",
        "partOfSpeech": "Suru noun",
        "explanation": "Used when encouraging or accelerating the progress of an activity, process, or development.",
        "commonCollocations": [
          "経済成長を促進する",
          "理解を促進する",
          "交流を促進する"
        ],
        "questions": [
          {
            "id": 1,
            "type": "meaning",
            "japanese": "政府は経済成長を促進するため、新しい政策を発表した。",
            "english": "The government announced a new policy to promote economic growth.",
            "question": "促進する means what in this sentence?",
            "options": {
              "A": "To prevent",
              "B": "To promote",
              "C": "To delay",
              "D": "To observe"
            },
            "correctOption": "B",
            "explanation": {
              "correct": "促進する means to promote or accelerate progress.",
              "wrong": {
                "A": "Preventing is the opposite of promoting.",
                "C": "Delaying means slowing progress.",
                "D": "Observing does not imply encouraging progress."
              }
            }
          },
          {
            "id": 2,
            "type": "sentenceCompletion",
            "japanese": "この活動は、国際交流を___することを目的としている。",
            "english": "This activity aims to promote international exchange.",
            "options": {
              "A": "促進",
              "B": "中止",
              "C": "制限",
              "D": "拒否"
            },
            "correctOption": "A",
            "completedSentence": "この活動は、国際交流を促進することを目的としている。",
            "explanation": {
              "correct": "交流を促進する is a natural collocation meaning to promote exchange.",
              "wrong": {
                "B": "中止 means cancellation.",
                "C": "制限 means restriction.",
                "D": "拒否 means refusal."
              }
            }
          },
          {
            "id": 3,
            "type": "correctUsage",
            "question": "Which sentence uses 促進 most naturally?",
            "options": {
              "A": "昨日、友達と促進を食べた。",
              "B": "彼は促進を着て学校へ行った。",
              "C": "運動は血液循環を促進する。",
              "D": "私は促進で駅まで歩いた。"
            },
            "correctOption": "C",
            "explanation": {
              "correct": "血液循環を促進する means to promote blood circulation.",
              "wrong": {
                "A": "促進 is not food.",
                "B": "促進 is not clothing.",
                "D": "促進 is not a means of transportation."
              }
            }
          },
          {
            "id": 4,
            "type": "incorrectUsage",
            "question": "Which sentence uses 促進 unnaturally?",
            "options": {
              "A": "政府は観光業の発展を促進している。",
              "B": "この薬は血行を促進する。",
              "C": "新しい制度は技術革新を促進する。",
              "D": "私は毎朝、促進を一杯飲む。"
            },
            "correctOption": "D",
            "explanation": {
              "correct": "促進 is an abstract noun referring to promoting progress, not a drink.",
              "wrong": {
                "A": "A natural use for promoting industrial development.",
                "B": "A natural use for improving circulation.",
                "C": "A natural use for encouraging innovation."
              }
            }
          },
          {
            "id": 5,
            "type": "collocation",
            "question": "Which expression is a natural collocation?",
            "options": {
              "A": "促進を食べる",
              "B": "促進を着る",
              "C": "理解を促進する",
              "D": "促進を眠る"
            },
            "correctOption": "C",
            "completedSentence": "理解を促進する",
            "explanation": {
              "correct": "理解を促進する means to facilitate understanding.",
              "wrong": {
                "A": "促進 cannot be eaten.",
                "B": "促進 cannot be worn.",
                "D": "促進 cannot be used as the object of 眠る."
              }
            }
          },
          {
            "id": 6,
            "type": "contextInference",
            "japanese": "会社は社員同士のコミュニケーションを促進するため、定期的な交流会を開いている。",
            "english": "The company holds regular gatherings to encourage communication among employees.",
            "question": "What is the company's purpose?",
            "options": {
              "A": "社員の会話を減らすこと",
              "B": "社員の交流を活発にすること",
              "C": "社員の人数を減らすこと",
              "D": "社員の仕事を禁止すること"
            },
            "correctOption": "B",
            "explanation": {
              "correct": "促進する implies encouraging more active communication.",
              "wrong": {
                "A": "Reducing conversation is the opposite.",
                "C": "The sentence does not mention reducing staff.",
                "D": "The sentence does not mention prohibiting work."
              }
            }
          }
        ]
      }
    ],
    "metadata": {
      "totalVocabulary": 1,
      "questionsPerVocabulary": 6,
      "totalQuestions": 6,
      "version": 1
    }
  };

  static Map<String, dynamic> getSampleN2KanjiUsage() => {
    "id": "n2_kanji_usage_001",
    "title": "Kanji Usage",
    "jlpt": "N2",
    "section": "Kanji",
    "tags": [
      "reading",
      "recognition",
      "meaning",
      "compound",
      "context"
    ],
    "kanji": [
      {
        "id": "soku",
        "character": "促",
        "onyomi": ["ソク"],
        "kunyomi": ["うながす"],
        "meanings": [
          "To urge",
          "To promote",
          "To accelerate"
        ],
        "strokeCount": 9,
        "explanation": "促 is used when encouraging someone to act or making a process move forward.",
        "commonWords": [
          {
            "word": "促進",
            "reading": "そくしん",
            "meaning": "Promotion; acceleration"
          },
          {
            "word": "催促",
            "reading": "さいそく",
            "meaning": "Urging; reminding"
          },
          {
            "word": "促す",
            "reading": "うながす",
            "meaning": "To urge; to prompt"
          }
        ],
        "questions": [
          {
            "id": 1,
            "type": "kanjiReading",
            "japanese": "政府は経済成長を促進している。",
            "english": "The government is promoting economic growth.",
            "question": "What is the reading of 促進?",
            "options": {
              "A": "そくじん",
              "B": "そくしん",
              "C": "しょくしん",
              "D": "ぞくしん"
            },
            "correctOption": "B",
            "explanation": {
              "correct": "促進 is read そくしん.",
              "wrong": {
                "A": "進 is read しん here, not じん.",
                "C": "促 is read そく, not しょく.",
                "D": "促 is read そく, not ぞく."
              }
            }
          },
          {
            "id": 2,
            "type": "kanjiSelection",
            "japanese": "会社は社員の交流をそくしんする。",
            "english": "The company promotes interaction among employees.",
            "question": "Choose the correct kanji for そくしん.",
            "options": {
              "A": "促進",
              "B": "即進",
              "C": "速進",
              "D": "足進"
            },
            "correctOption": "A",
            "completedSentence": "会社は社員の交流を促進する。",
            "explanation": {
              "correct": "促進 is the correct spelling for promoting progress.",
              "wrong": {
                "B": "即 means immediate, but 即進 is not the intended word.",
                "C": "速 means fast, but 速進 is not the intended word.",
                "D": "足 means foot, and 足進 is not the intended word."
              }
            }
          },
          {
            "id": 3,
            "type": "kanjiMeaning",
            "question": "What is the core meaning of 促?",
            "options": {
              "A": "To stop",
              "B": "To forget",
              "C": "To urge",
              "D": "To hide"
            },
            "correctOption": "C",
            "explanation": {
              "correct": "促 means to urge, prompt, or encourage progress.",
              "wrong": {
                "A": "Stopping is unrelated.",
                "B": "Forgetting is unrelated.",
                "D": "Hiding is unrelated."
              }
            }
          },
          {
            "id": 4,
            "type": "similarKanji",
            "question": "Which kanji is used in うながす (to urge)?",
            "options": {
              "A": "捉",
              "B": "足",
              "C": "促",
              "D": "従"
            },
            "correctOption": "C",
            "explanation": {
              "correct": "促す is read うながす.",
              "wrong": {
                "A": "捉 is used in 捉える.",
                "B": "足 means foot or sufficient.",
                "D": "従 means follow or obey."
              }
            }
          },
          {
            "id": 5,
            "type": "compoundWord",
            "question": "Which word means to urge someone to respond or act?",
            "options": {
              "A": "催促",
              "B": "促進",
              "C": "約束",
              "D": "予測"
            },
            "correctOption": "A",
            "explanation": {
              "correct": "催促 means urging someone to do something, often through reminders.",
              "wrong": {
                "B": "促進 means promoting progress.",
                "C": "約束 means promise.",
                "D": "予測 means prediction."
              }
            }
          },
          {
            "id": 6,
            "type": "contextUsage",
            "japanese": "先生は学生に自主的な学習を___。",
            "english": "The teacher encourages students to study independently.",
            "question": "Choose the most appropriate expression.",
            "options": {
              "A": "促した",
              "B": "防いだ",
              "C": "隠した",
              "D": "失った"
            },
            "correctOption": "A",
            "completedSentence": "先生は学生に自主的な学習を促した。",
            "explanation": {
              "correct": "促した means encouraged or prompted.",
              "wrong": {
                "B": "防いだ means prevented.",
                "C": "隠した means hid.",
                "D": "失った means lost."
              }
            }
          }
        ]
      }
    ],
    "metadata": {
      "totalKanji": 1,
      "questionsPerKanji": 6,
      "totalQuestions": 6,
      "version": 1
    }
  };

  static List<VocabularyTopicModel> getInitialSampleVocabTopics() {
    return [VocabularyTopicModel.fromMap(getSampleN2VocabUsage())];
  }

  static List<KanjiTopicModel> getInitialSampleKanjiTopics() {
    return [KanjiTopicModel.fromMap(getSampleN2KanjiUsage())];
  }
}

List<GrammarTopicModel> getInitialSampleGrammarTopics() {
  return SampleGrammarData.getInitialSampleGrammarTopics();
}

List<VocabularyTopicModel> getInitialSampleVocabTopics() {
  return SampleGrammarData.getInitialSampleVocabTopics();
}

List<KanjiTopicModel> getInitialSampleKanjiTopics() {
  return SampleGrammarData.getInitialSampleKanjiTopics();
}
