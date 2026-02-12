'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "a14baf7b480a6688ecd2122b03c2faa0",
"assets/AssetManifest.bin.json": "0df6ebf50f6a1fcb5244a317c001fb5e",
"assets/AssetManifest.json": "af769227e7f8526026c7881ca7f80779",
"assets/assets/audio/Aa.wav": "c2c98a576465a6d47b98d7f13fc721eb",
"assets/assets/audio/aac.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aah.wav": "b486dd0e716a835a2a51c696f9ea92a5",
"assets/assets/audio/aah_loc.wav": "d5b97815235a57465d3f3bd574b297f9",
"assets/assets/audio/aah_yiz.wav": "e45efd6448c9b5e5a210590a0b23608a",
"assets/assets/audio/aamx_fangx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aamx_fangx_zorngh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aamx_sou.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aanx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapc.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv.wav": "e123cd6d887af5981c078d7e797a57d9",
"assets/assets/audio/aapv_biei.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv_dorn.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv_gorngx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv_hoic.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv_jaanx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv_jaax.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv_mbienx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aapv_ngorh.wav": "8821a01f1ddec4163e7f69126802e84a",
"assets/assets/audio/aapv_nyeiz.wav": "e841c20006121151588b5b42a9e52aca",
"assets/assets/audio/aapv_wuom.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aauv.wav": "3f9eaf1451a747afd4fc0c3173ca080d",
"assets/assets/audio/aaux.wav": "3482c07239807578ab42c1c0dfb12804",
"assets/assets/audio/aaux_lungh.wav": "1f7196642164a091f600c8b0b1e0c1ea",
"assets/assets/audio/aauz.wav": "9bf4853fc8a2ba398a251135a384c239",
"assets/assets/audio/aav.wav": "07c46ddbf5b5c1a3fc455e04ae8114d6",
"assets/assets/audio/aav_dangh.wav": "f85fc149997655d41e0b24fc1df2d11f",
"assets/assets/audio/aav_haenv.wav": "ca803a30d22030bc68c483e20038c79c",
"assets/assets/audio/aav_hitv.wav": "911184d1ac467eed8defd55a5a094429",
"assets/assets/audio/aav_hitv_dangh.wav": "13a31d8a6498aba71fd21b2729db625c",
"assets/assets/audio/aav_hitv_deix.wav": "bbf0d8b4213a164e946894bda19f7c11",
"assets/assets/audio/aav_lamh.wav": "4f88c29e25c49aa094684666b7faf4f4",
"assets/assets/audio/aav_lov.wav": "59a07da808b95c517809e42bcefd0f03",
"assets/assets/audio/aav_maah.wav": "af9bc071c27e9e6508aeaf439ab6d199",
"assets/assets/audio/aav_yov.wav": "a26efa0d5fd10630f3742487896e6f9b",
"assets/assets/audio/aav_zuqc.wav": "8f8c7ccf1c36a9ec8d025e6a09fa3035",
"assets/assets/audio/aax.wav": "be3e0815729186400df9fe30354b4de4",
"assets/assets/audio/aayoh.wav": "16581a18ac073722d5c49c2108bcab3b",
"assets/assets/audio/Aa_Cic.wav": "e9ade7182b27ce0a0df5b2845a348d3a",
"assets/assets/audio/aa_cingx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aa_cingx_jang.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aa_dae.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aa_die.wav": "086c2ce26e0f7b21d63608d00fde1258",
"assets/assets/audio/Aa_Div.wav": "cd5f1065392ac39ab8abc7dad3647fbb",
"assets/assets/audio/aa_dorc.wav": "cc091b6cfb1bbd13fded6ff41cc2b885",
"assets/assets/audio/Aa_Dorn.wav": "14ae334d3b58c5ee49c31d93937c6be2",
"assets/assets/audio/Aa_Dutv.wav": "eea8b486b9bfe80340731c12b89f4081",
"assets/assets/audio/aa_gorx.wav": "c283888d703bc8c35d3b983ca048592f",
"assets/assets/audio/Aa_Guv.wav": "505dd99ac8f292d7aca59e71573ec0b5",
"assets/assets/audio/aa_jang.wav": "5cf986c0eaa8da8c279560ed96027584",
"assets/assets/audio/aa_maa.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aa_mangc.wav": "834615d5ef731f1398951c713943070d",
"assets/assets/audio/aa_ndorm.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/Aa_Nyanv.wav": "1b9628384349a9b12baf533802337710",
"assets/assets/audio/aa_nyei.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/Aa_Nyingv.wav": "13c705235a107c1a5e6db3151e17d507",
"assets/assets/audio/Aa_Sieqv.wav": "54d0962fc520010b754141d20a618f23",
"assets/assets/audio/aa_yaah.wav": "153b59806439b3a44b0e5cc3aed239e9",
"assets/assets/audio/aa_yaav.wav": "6228abdad523809d3a8611fd14d86e74",
"assets/assets/audio/aa_yoz.wav": "f1a35a9c8ae9ff3646897a204506742a",
"assets/assets/audio/aa_yuv.wav": "30755126e5ada9d51d531086927426cf",
"assets/assets/audio/aec.wav": "314097b283adb2344d1d87cbf4e02e2f",
"assets/assets/audio/aec_ngorngc.wav": "3ca4d0334a28a29f361a0efc2bf706f2",
"assets/assets/audio/aeh.wav": "479b764da9df33a9b30b218c1650d760",
"assets/assets/audio/aeng.wav": "3a605c03c5e6b560415caf86fff08ad4",
"assets/assets/audio/Aengh_Doih.wav": "4dda6284181f93c3655bc8f9b3d4bf2d",
"assets/assets/audio/aengv.wav": "4279e17da7d2310153adf6ce3575068f",
"assets/assets/audio/aengv_njoiz.wav": "ba29fa3beea2805de3727b52d9b458e0",
"assets/assets/audio/aengx.wav": "ad8c50e59b2bc52512dfbd2c4af0b22b",
"assets/assets/audio/aenh.wav": "9dd08df6999add46dab3b1fd67a3d0a0",
"assets/assets/audio/aepv_bouh.wav": "5cf302bbf8c5f9906ca6ed866e54504a",
"assets/assets/audio/aeqc.wav": "ec73b2353fbe30088fad9c67f30966ed",
"assets/assets/audio/aeqv.wav": "26a78b5dee50c30cc07b1e7291cd0542",
"assets/assets/audio/aetv.wav": "99ec1015f9c4d7ca76ea7c9eae496243",
"assets/assets/audio/aev.wav": "0ce3c06d140b0aec876f2170fd9323f2",
"assets/assets/audio/aev_div.wav": "72ba097a4c23a71a356c0dfff3750786",
"assets/assets/audio/aev_nzae.wav": "92ec182a45e52258d03bf893556c114c",
"assets/assets/audio/aex.wav": "9591e2cab3e35cab66627c9b540b8054",
"assets/assets/audio/aih.wav": "9766654e4a7fc7ee4b43ae5f593d4037",
"assets/assets/audio/aiqc.wav": "6fbb7c20a55614e2751e1224460412df",
"assets/assets/audio/aiv.wav": "4e6d4ef058df2a4e5d6e7b762aa4b490",
"assets/assets/audio/aix.wav": "f5baecbff2885988039617dcd5c6c33e",
"assets/assets/audio/Amegaa.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/amv.wav": "8e6563bee5be8614ef0174d553453075",
"assets/assets/audio/an.wav": "0337bc991aa7db2454a1efeab9ad0c93",
"assets/assets/audio/anx_zaqv.wav": "57d11b42e6c8b92185af4a7480f5b0fd",
"assets/assets/audio/apc.wav": "47191b94851068aa0fae91260c72485c",
"assets/assets/audio/apc_hmuangx.wav": "4e272a691c715c22eaeeb62d7134ac84",
"assets/assets/audio/apc_hnoi.wav": "09d9bce21b64dfd390f83c27f49b05fa",
"assets/assets/audio/apc_hnoi_aanx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/apc_hnoi_hmuangx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/apc_hnoi_ndorm.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/aqc.wav": "c9f99ec30ac37d2fcdd76863936d141c",
"assets/assets/audio/aqc_div.wav": "2806edc7ab97e7a080eef623e10923c3",
"assets/assets/audio/aqc_mangc.wav": "dfaecbbb9bb13512027440952c809b2c",
"assets/assets/audio/aqc_muangx.wav": "b08cc33faefb90500de3927419d34372",
"assets/assets/audio/aqv.wav": "c3368584291b5f34f61c5c535437a64b",
"assets/assets/audio/aqv_zuqc.wav": "c3eefb393a1da9de14c2ca359e0de648",
"assets/assets/audio/atv.wav": "56a5520977a0f954af688631f06aa00e",
"assets/assets/audio/atv_waac.wav": "d783d28daf91f2dc096cc122d8141e5b",
"assets/assets/audio/auv.wav": "b57c3ffc08646f21926de5070866c5f9",
"assets/assets/audio/auv_biqv.wav": "5958640cc0b415a8b0fa9d038d446444",
"assets/assets/audio/auv_dorn.wav": "9c7f3797802c1ec869cb946eea02b257",
"assets/assets/audio/auv_guaav.wav": "1633df2c4ce1470eb26718f1b666e69d",
"assets/assets/audio/auv_hlo.wav": "07c96bdcba031d2ffe4a3d13ed135668",
"assets/assets/audio/auv_jueiv.wav": "015811c92aaae4c7609681b92e0d23a6",
"assets/assets/audio/auv_leih.wav": "babccc90692de93d95214b563ebdc3d9",
"assets/assets/audio/auv_nqox.wav": "128123cd85cb8d6c888c8f9d248739b7",
"assets/assets/audio/auv_nqox_doic.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/auv_saeng.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_cingx.wav": "8dbf5ddbd72773ccf7e7e2f8e757b6d9",
"assets/assets/audio/a_cingx_jang.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_haenv.wav": "fbc07a05d9a3102bd2884487fe844bde",
"assets/assets/audio/a_hmuangx.wav": "e68155c52c6f53d4ac3a3b79de78df76",
"assets/assets/audio/a_hneiv.wav": "6537d608df8d39b7063ba4a5484d161e",
"assets/assets/audio/a_hnoi.wav": "ed60cb7cb202de68c91e9b75e6106d5e",
"assets/assets/audio/a_hnoi_ndorm.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_jang.wav": "91c594252ba5b5f2d1973ab067eafb0f",
"assets/assets/audio/a_lanh.wav": "e64012d7a22d55f090ddf64914ed4777",
"assets/assets/audio/a_mangc.wav": "0b79533b087cf053252d2815219f7b56",
"assets/assets/audio/a_muangx.wav": "e4bdd08d0a83a851ac4112ea0629149b",
"assets/assets/audio/a_ndorm.wav": "c90965a152263609b2f3d8f91918ee7d",
"assets/assets/audio/a_nziaauc.wav": "16ae349490c4bf77773a94e57e9c7ec9",
"assets/assets/audio/a_nziaauc_baengc.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_nziaauc_ciangv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_nziaauc_doic.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_nziaauc_dorngx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_nziaauc_mbuox.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/a_nziaauc_waac.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baa.wav": "6d6bffcf8502d470e59dbb03cf432a3f",
"assets/assets/audio/baac.wav": "585a984dfd8a954c68f69763392e9624",
"assets/assets/audio/baac_baac.wav": "2a89c24189ac4b5ac25b1025c48a5bf9",
"assets/assets/audio/baac_ix.wav": "d9ee3b0cf09fea74c38008b0579319ad",
"assets/assets/audio/baah.wav": "bc6bc8b0d69b3e572fb3d19a62ac6519",
"assets/assets/audio/baah_maah.wav": "f5d9b829ce74d128830a049c7cdb9063",
"assets/assets/audio/baaic.wav": "d6e6b3a0db3097f5e0505af8842ec79d",
"assets/assets/audio/baaih.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baaiv.wav": "2bafb0a2d8dc122d641b9ebb2a64f518",
"assets/assets/audio/baaix.wav": "15d06bc7e71e73b0c2bb62d3cac270a5",
"assets/assets/audio/baamh.wav": "67ab7c918d18621c9fbe0eb214b5d1e9",
"assets/assets/audio/baamh_gen.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baamh_mienh.wav": "d74292532dd6778fc72175149a251664",
"assets/assets/audio/baamz.wav": "34a8a8c3f0ff40290bc83ce9ccc97d59",
"assets/assets/audio/baan.wav": "952fecdd75000883ca7e385e0c403acb",
"assets/assets/audio/baanh.wav": "ec76f548a7a29e5f5234361d60590982",
"assets/assets/audio/baanx.wav": "f3aa126d7c091254d6b9fa0d52a881ca",
"assets/assets/audio/baan_buic.wav": "e5cfc87694772521cc0d48aa3b1b0f56",
"assets/assets/audio/baan_buic_daan.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baan_sic_mienh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baatc.wav": "c7d9d5066ed82e0c308d081fd068674b",
"assets/assets/audio/baauh.wav": "9d3b948f8e1452aad199e8e6a06044aa",
"assets/assets/audio/baauv.wav": "97d49eaf57f93fc1086012dc9c1ecad4",
"assets/assets/audio/baaux.wav": "820ac8a4b2d59bdb7954c6f024270984",
"assets/assets/audio/baav.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/Baav_bouc_fin_saeng.wav": "1f1d35ebe2c6d12e9a898ad255214cb6",
"assets/assets/audio/baa_baa.wav": "29b5425e86fae3a2bd2f39bc1227d612",
"assets/assets/audio/baen.wav": "3066941c9dfe950ceaf056ef11558565",
"assets/assets/audio/baeng.wav": "7fd438a4142e17dd01629154bf11b32f",
"assets/assets/audio/baengc.wav": "0b5eb0ec5738df730ba6c761a43441f8",
"assets/assets/audio/baengc_ciou.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baengc_fei.wav": "405b812a44a2a663dcbe2a05969f196a",
"assets/assets/audio/baengc_fouh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baengc_gorn.wav": "9e1f779246e7def8a99b9ab547f0b8e6",
"assets/assets/audio/baengc_hniev.wav": "30294f48952a006068af101826661e40",
"assets/assets/audio/baengc_hnopv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baengc_mbai.wav": "3daa8e7775cb52aefe6d41e7362c79e6",
"assets/assets/audio/baengc_meih.wav": "06262317bd6b09484aeae2e414b93aca",
"assets/assets/audio/baengc_mienh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baengc_ngaaiz.wav": "2935fe4ef11b3f294f286c4eb89f8362",
"assets/assets/audio/baengc_njortc.wav": "718a651823a99eea5223aa4f9878cf9f",
"assets/assets/audio/baengc_nyiez.wav": "9ad9e57f1b957fe4cf327377f71abd60",
"assets/assets/audio/baengc_omx.wav": "643df1ac12e0c2fcf0a1a3cb993aeb0d",
"assets/assets/audio/baengh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baengh_baaiz.wav": "1d7f1abffcc872c392ce71f2f45d6f3a",
"assets/assets/audio/baengh_buoz.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baengh_jouh.wav": "aad2ba9f21cc087523c071185dbbdb49",
"assets/assets/audio/baengh_leiz.wav": "5255481c6e0f344619f7adc0950fca02",
"assets/assets/audio/baengh_nuov.wav": "9ca3d23cac20d8ec3425ead7f511e4fc",
"assets/assets/audio/baengh_orn.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baengv.wav": "5783bd07148a21736dcbb2e03f5638da",
"assets/assets/audio/baengx.wav": "d6117e4d9a4cc3e388a0034b2f6c5377",
"assets/assets/audio/baeng_bieiv.wav": "a633e63758e4ac7df50e331fd1c74927",
"assets/assets/audio/baeng_ciangv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeng_lungh.wav": "393a3ade8ff9110eab498468ff5cabfe",
"assets/assets/audio/baeng_maanh.wav": "981625d1251d62dfd9fa043e1f7ac012",
"assets/assets/audio/baeng_maaz.wav": "b268896f5e8869db6613cc0ccca2f11c",
"assets/assets/audio/baeng_nziaamv.wav": "de084d5f80dcbb66257af82a1255bde3",
"assets/assets/audio/baeng_wuom.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeng_zaamc.wav": "cc35626ff4e8183951c82124eb8f5cb6",
"assets/assets/audio/baeqc.wav": "36f30f45caed07059decbce82c03e84c",
"assets/assets/audio/baeqc_baeqc.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqc_baeqc_sin.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqc_citv.wav": "27a4181d8b1d14a8837928d037084d2d",
"assets/assets/audio/baeqc_gopv.wav": "13ddbc12488ce45f775b822e6ff16d7d",
"assets/assets/audio/baeqc_horqc.wav": "55d04eb03d55ec367ac3a8f583bee2e6",
"assets/assets/audio/baeqc_horqc_biangh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqc_kuaa.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqc_kuaa_naamh_zaangv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqc_mbuonv.wav": "91e1116a6a99d5936bf530bc2fe9dfff",
"assets/assets/audio/baeqc_mbuov.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/Baeqc_Miuh.wav": "3f4d04c75b8de4bea0e24c6bf41a5afa",
"assets/assets/audio/baeqc_waac.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqc_yieqc.wav": "4833f2931cc407bcb37ad1ceae7dfa0f",
"assets/assets/audio/baeqc_ziangh_zeiz.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqv.wav": "69f30a5175cabc1fdc27a5997fb8e5fc",
"assets/assets/audio/baeqv_betv.wav": "e32c4d7f53d78b5480a759dee5a82fce",
"assets/assets/audio/baeqv_cietv.wav": "8230407e3085b066edf101d03f9720c8",
"assets/assets/audio/baeqv_faam.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqv_feix.wav": "967ad3f52c57aa15a92ace71d6826568",
"assets/assets/audio/baeqv_fingx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqv_hmz.wav": "17f778cace12349522b774b27799ef71",
"assets/assets/audio/baeqv_juov.wav": "0279e011d40fc2bec2efd17f6ac70f6d",
"assets/assets/audio/baeqv_luoqc.wav": "cb4b5db0eae12134b7826fc2f58864c2",
"assets/assets/audio/baeqv_muoz_doic.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqv_nyeic.wav": "e4ec1873aff61342a1878ad5c0cb56fa",
"assets/assets/audio/baeqv_ong.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baeqv_yietv.wav": "3dcd384a7aa51170557e5c5d5b6981bb",
"assets/assets/audio/baetv.wav": "b6c1faba9a3335b1ecd5ad6f5b34486e",
"assets/assets/audio/baic.wav": "00e85b036af94359dc14e0903821f21e",
"assets/assets/audio/baih.wav": "df92f3c53979b81e04e69d36f54f1ece",
"assets/assets/audio/bakv.wav": "fb3a957d23c0a56af581a2820f0be6dc",
"assets/assets/audio/bamc.wav": "5c55ca5fa034691510d138630950f240",
"assets/assets/audio/bamc_haic.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/ban.wav": "ff6838547f68e99cba70f17850e3182b",
"assets/assets/audio/bang.wav": "5c0dc4dc4d204d41642169bad8241cab",
"assets/assets/audio/bangc.wav": "20e284740f29d16890d8a3f480788657",
"assets/assets/audio/bangc_kaux.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bangv.wav": "a3a421d185bd00ddf7ddd0fb381e6893",
"assets/assets/audio/bangv_hlo.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bangx.wav": "55c8a9eaaf33c1b753dca5a83ae16702",
"assets/assets/audio/bangx_jienv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/banh_zeic.wav": "2c172aebddbe7b22fbd463f9f315bd9e",
"assets/assets/audio/banv_youh.wav": "b910b994dd3bc063472da0ec5c2b3167",
"assets/assets/audio/baqv.wav": "d0e413f448da93f04e3a71518a7b11f2",
"assets/assets/audio/baqv_bung.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baqv_dauv.wav": "6727375ea5179ac5b7a50d34db996b0a",
"assets/assets/audio/baqv_dong_bung.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/Baqv_Ging.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/baqv_ndie.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/batc.wav": "1a35e20a0127a7f66363e9d5148399e5",
"assets/assets/audio/batv.wav": "9728fd0472a5321912d9e975f8bf6455",
"assets/assets/audio/batv_biei.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/batv_nqaaix.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/batv_sortv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bau.wav": "b111027034d75d723dea0eba82fa22e8",
"assets/assets/audio/bauc.wav": "8d8c7cebe528071f932aca0a42c142ab",
"assets/assets/audio/bauv.wav": "445d4aee43654314aa0b6960b20bcf47",
"assets/assets/audio/baux.wav": "3421bdb68bb6f4768c098d74aff66a4e",
"assets/assets/audio/ba_.wav": "6153a1f8bb21cc8e1993c30be8a70c74",
"assets/assets/audio/ba_daatc.wav": "a62551d91c3a53f264b469ec63bbcf4c",
"assets/assets/audio/ba_gern.wav": "745830fc49e6e3bd9b5dce2947e697d2",
"assets/assets/audio/ba_gern_cenv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/ba_gi.wav": "3a6e8f9469c8fc187b28ed8d612fbd55",
"assets/assets/audio/ba_gi_yungh.wav": "2ced84db95c2eb21040f9b32fdd33cf4",
"assets/assets/audio/ba_hnoi.wav": "179eb17d540d95e5c29e6b3eb49a669b",
"assets/assets/audio/ba_hnoi_haaix.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/ba_hnyangx.wav": "c6535e36ba9c776ddd1225ccdfb96768",
"assets/assets/audio/ba_ingv.wav": "80d233a9905a16c8b0553a6819d9dd6d",
"assets/assets/audio/ba_jaauh.wav": "89489892bdab8264db992aa93c027e60",
"assets/assets/audio/ba_jaauh_njang.wav": "7fbc7070900dca0a94c3a71d8366d064",
"assets/assets/audio/ba_jien_dauv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/ba_juonh.wav": "a1124314dd5921e0c36804f4c1dd5b2b",
"assets/assets/audio/ba_laqc.wav": "f45af8d81e314ae61146f6e126ab4984",
"assets/assets/audio/Ba_longh_Zeuz.wav": "39dd8af139ef8e0040b049aa8104b7b8",
"assets/assets/audio/ba_lorngh.wav": "24baf57dde7ec2afc358b0d466011d69",
"assets/assets/audio/ba_lorngh_qorngh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/ba_norngz.wav": "c04bca9c70c5b62d7a780782ddd0a703",
"assets/assets/audio/ba_nyaic.wav": "37805af0e4e942e922330dbcbf4c1403",
"assets/assets/audio/ba_zi_ba_ziaa.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bei.wav": "d0222af01f769c29509cc1ca8b7ccd5f",
"assets/assets/audio/beic.wav": "a494e5a218389af44d0951e4f0872938",
"assets/assets/audio/beic_ndiev.wav": "cac3ca7a227c67249335e724679958e0",
"assets/assets/audio/beic_sih.wav": "497e5e2223ccb765fa7b576538a29972",
"assets/assets/audio/beic_waanc_jaa.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/beih.wav": "afce88b375d3168682f51255a7299f30",
"assets/assets/audio/beiv.wav": "f4a8dd3f3083b8f7d9b477fe1ae104b8",
"assets/assets/audio/beix.wav": "7e01453640d7878685883178dd7bda07",
"assets/assets/audio/beix_yuc.wav": "6fad3573b0776d258d3fb619e43e91a8",
"assets/assets/audio/ben.wav": "e982a226f898de269ba6111f33e152ce",
"assets/assets/audio/benc.wav": "65d567d99a58087799d61193b6d1a8e6",
"assets/assets/audio/bengv.wav": "05cf1f83389ee96ed3c9c65af2baf4c1",
"assets/assets/audio/bengv_deng.wav": "e90b68faa4fe387934f844b959b5a251",
"assets/assets/audio/bengv_futv.wav": "f7df59ac56d430adeae3b10cd728ef13",
"assets/assets/audio/bengv_hmz.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bengv_sien.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bengv_yienh.wav": "1b74d2228236ae1bec4f7adf6219a2a5",
"assets/assets/audio/bengv_zaanh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bengv_zeiv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/benh.wav": "e3438d3f58b6115e49ae0cb7bbac9919",
"assets/assets/audio/benh_sui.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/benv.wav": "1c80c044af69acc4aeabf16104e12e80",
"assets/assets/audio/benx.wav": "5e8e59121b188eac02d8be7bd21ae3d2",
"assets/assets/audio/benx_zuqc.wav": "b9a361045a9d96a8231442b080eb830b",
"assets/assets/audio/beqv.wav": "e58f4bb2e45e830040c059f398b03c32",
"assets/assets/audio/bernx.wav": "7882fdd06966e4f1a094a5b212cb3353",
"assets/assets/audio/betc.wav": "86bf1ff19df1ba59d900fd63bb34062a",
"assets/assets/audio/betv.wav": "f56461d71b30a3c08a8e4efbc3527dd4",
"assets/assets/audio/betv_baeqv.wav": "00899a98352fb60dbbd86a7df253cf9d",
"assets/assets/audio/betv_fin.wav": "417637cdd822a14ecee1f1b01a5c867d",
"assets/assets/audio/betv_gorqv.wav": "9ebc35dcc5a9d1da23a3f921a1d7237e",
"assets/assets/audio/betv_hlaax.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/betv_ziepc.wav": "74618f47ae634646162069b43c6aba68",
"assets/assets/audio/beu.wav": "733580ecd9ada090685bdd9dc9605c6c",
"assets/assets/audio/beuh.wav": "9ea84e61d5cac504b9a88e56aa96bb05",
"assets/assets/audio/beuv.wav": "3d2a2b23726ff1923e476768025b5499",
"assets/assets/audio/beu_sengh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/beu_sengh_laengz.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/beu_sengh_sou.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biaa.wav": "c7dae7550ca222f68b5e3fcafb345366",
"assets/assets/audio/biaah.wav": "6f51ef87ac0b51ab3005f0a82863bb07",
"assets/assets/audio/biaaix.wav": "a0792986223697ca90e2d73d43821dbd",
"assets/assets/audio/biaapc.wav": "30c1f009386cdbdb984339d53999f634",
"assets/assets/audio/biaapv.wav": "5e696015b90fa83a6af5746a1ef48358",
"assets/assets/audio/biaav.wav": "246cf2a166a0ffe85c7562caeb479f0a",
"assets/assets/audio/biaav_bin.wav": "cf1a81aef7523d99fd456bef2bbd2ca0",
"assets/assets/audio/biaav_lorngh.wav": "d5f25ff42d073ff158fdfc24f1962754",
"assets/assets/audio/biaav_mbiaac.wav": "2cbc8e6a64ac2bb40dffd71d51258b07",
"assets/assets/audio/biaav_ndorqc.wav": "ce1bb47562783b099b9b291c2d6382f3",
"assets/assets/audio/biaav_sorqv.wav": "bcda44a81b69d7583d8de5a5203c6cbd",
"assets/assets/audio/biaa_bung_weic.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biaa_cin.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biaa_sinx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biaa_waanc.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biaa_waanc_hmz_baeqv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biaengh.wav": "df4837133e61379bb960b6a3824f87ce",
"assets/assets/audio/biangh.wav": "a2b523801bf77bb9e871ad9ee1382b72",
"assets/assets/audio/biangh_liemh.wav": "c907fefebb083873ae4015ee5c786ce1",
"assets/assets/audio/biangh_mienv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biangh_nzai.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biatc.wav": "58aee1b0c58ee9ae63578368c09b62e8",
"assets/assets/audio/biau.wav": "5bc39bdb0a7f166503b1a290eab920b4",
"assets/assets/audio/biauv.wav": "5c52d6764abe9291ccf6c1b3a6128305",
"assets/assets/audio/biauv_fangx_zaangc.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biauv_hlen.wav": "9e4385623f1e085f2aa9be7c72c6c1ac",
"assets/assets/audio/biauv_menc.wav": "4e8979f8f5d306c49a90af53cb33a177",
"assets/assets/audio/biauv_namx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biauv_ziouv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biauv_zong.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biaux.wav": "14b20dd4c2ce5083f50c5f5addfb31a9",
"assets/assets/audio/bie.wav": "f81b9eaa0fd82eb70717216e82bd523f",
"assets/assets/audio/biec.wav": "2bf230a659e97282349595e035473efe",
"assets/assets/audio/biei.wav": "21625c1375c3afeccf20ddfe011e6b2b",
"assets/assets/audio/bieiv.wav": "1a21c19a541cb49faeef717a7c03b71c",
"assets/assets/audio/biei_bung_weic.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biei_cin.wav": "83182e7e896d99766251f1b2831a2de9",
"assets/assets/audio/biei_sinx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biei_waanc.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bien.wav": "9188958f41a3d155e1168086252db7f5",
"assets/assets/audio/bienh.wav": "71f8539ee7c244d70cf24d2b57ae5061",
"assets/assets/audio/Bienh_Hungh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/Bienh_Hungh_Mienv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/Bienh_Hungh_zipv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bienv.wav": "0cf1622481ac76452f656ad451571329",
"assets/assets/audio/bienx.wav": "ad8691f241aebc440c5bb2d44995e3ab",
"assets/assets/audio/bieqc.wav": "100d7a99ebdea5131e429ea568df15a5",
"assets/assets/audio/bieqc_hnyouv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bieqc_loh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bietv.wav": "95fbe19e96a50f20a861536eb8cbe8d5",
"assets/assets/audio/bih_bungx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bin.wav": "5054c2e181fb9cd25116096ef7bfb9b3",
"assets/assets/audio/binc.wav": "cc5f492ac516b314f204f029b87cf0a8",
"assets/assets/audio/bingv.wav": "2a0c71df828fd75c0c930dd55ee2b404",
"assets/assets/audio/bingx.wav": "d26ca00434eb70143adc655357841045",
"assets/assets/audio/binh_jouh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/binv.wav": "14340e41bd65b4a3baaaa3f3cc24650e",
"assets/assets/audio/binx.wav": "f6046b1731bb799924e890c5ae0f157b",
"assets/assets/audio/binx_binx.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/bioh.wav": "f5238ecfbf6ca6f9aaae0f1ead70176d",
"assets/assets/audio/biom.wav": "2fe54e6f74c9ecf745763914a8a6b9bc",
"assets/assets/audio/biomh.wav": "b9a30b52fe135082116320eaf0c678ef",
"assets/assets/audio/biomv.wav": "99dcdb30fc9f48de2fb1b14829f9e58c",
"assets/assets/audio/biomv_faatv.wav": "15e932e3675ba609cb3f41b48fb5cfaf",
"assets/assets/audio/biomv_mba_biei_ga_naaiv.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biomx.wav": "adc2025fdf77ec001fe82fb3c451fdcc",
"assets/assets/audio/biom_maeng.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biom_ndaix.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biongc.wav": "6998d5b10e0e8958e36a95ccb2b6edb3",
"assets/assets/audio/biopc.wav": "6a37f783c5d011642f0d721b8600dc00",
"assets/assets/audio/biopv.wav": "f5567fc6f62e15a92dad8b48b62b6468",
"assets/assets/audio/biormh.wav": "66e6587caf283d7eb2e5e72fe040de01",
"assets/assets/audio/biornc.wav": "dd95149fa8cfe740acf14d04b98f17b9",
"assets/assets/audio/biorngh.wav": "a9b2d99938aefd2e4ad9cb0a339a7787",
"assets/assets/audio/biortc.wav": "e59a443e2ec21d4e5ad7d3b54c727cb7",
"assets/assets/audio/biouv.wav": "14e7209f1bb4f242d74c778cb6d444a3",
"assets/assets/audio/biouv_gomh.wav": "9eec5635e83d85b2850c74ad66becde9",
"assets/assets/audio/biouv_hliangv.wav": "a57d805fc009816fbac9767548478ad7",
"assets/assets/audio/biouv_jaauh.wav": "0f15cbf017462e7c8a81351911a12b6f",
"assets/assets/audio/biouv_lorngh.wav": "12dd9923d2e49dfd0789623c3a5bad44",
"assets/assets/audio/biouv_lorngh_zong.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biouv_ndiangx_gong.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biouv_ndom.wav": "641e393d5c783830b2451952a390ebda",
"assets/assets/audio/biouv_zuei.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/biqv.wav": "39500386f8ce59b97aba0e1f151549f8",
"assets/assets/audio/bitv.wav": "06754529f3e0de7f8e3a68108ff7686d",
"assets/assets/audio/biu.wav": "fa9af9176dcac9f5da1c53b3249da029",
"assets/assets/audio/biuih.wav": "9fd189f2fd37fc0fb8e7ae226c1bc4ae",
"assets/assets/audio/biuqv.wav": "69e595f90e54bd013266d2b8db8b3df7",
"assets/assets/audio/biuv.wav": "268493146ade4ce8777a7356d89c8b0a",
"assets/assets/audio/biux.wav": "a8f11f0205ca44da67e38065098903db",
"assets/assets/audio/bix.wav": "d2b1f9acca088d7757d575f0cb89e1a2",
"assets/assets/audio/bom.wav": "38dcf8c52bb08e439f14e24bc24d8b41",
"assets/assets/audio/bongh.wav": "9ff377673a47a3edac776dc3f1464ac3",
"assets/assets/audio/bongv.wav": "4cdb32eeb3f5ad522d92da41d2fbf5fd",
"assets/assets/audio/bongv_gaex.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/borh_norz.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/born.wav": "69f76e547923bbb615a3c29a5654b673",
"assets/assets/audio/borng.wav": "ed9d78aebc5d3848b150f81f2a180db3",
"assets/assets/audio/borngv.wav": "8d89026af75ac3f778f7cbe2d07b503a",
"assets/assets/audio/borngz.wav": "09520ff7cc76578a6c1604874afd02ac",
"assets/assets/audio/borngz_jaax.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/borngz_mba_lingc.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/borngz_mba_ong.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/audio/borng_buoz_mienh.wav": "a539ebd5da61daab8a2d21e7f3b5ee58",
"assets/assets/data/mien_dictionary_feb12.csv": "4a9a3d5f690e9702c743c812478bf594",
"assets/assets/data/mien_dictionary_feb12.json": "09aa44648119c09d3a427305c5452ea4",
"assets/assets/data/mien_dictionary_feb8.csv": "014d855b73b631c729415177c799315d",
"assets/assets/data/mien_dictionary_feb8.json": "f0091652cb760162b3b50b9e86fcd724",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "252a2f2e6666feba526356587dcf59e0",
"assets/NOTICES": "62b48940a7ea17428a4634ba42fb4992",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "6461de49cb5f1d733ebfad0c7834b1e2",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "952db3a7c29148c68f855c945599e2b6",
"/": "952db3a7c29148c68f855c945599e2b6",
"main.dart.js": "d44064bedead0032ab239004ec0cc783",
"manifest.json": "1563eb4f42bcc071cf06e2bdafd45381",
"version.json": "db240426156f7d9a1ad065b75d792b69"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
