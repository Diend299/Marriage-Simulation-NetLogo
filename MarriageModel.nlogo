globals [
  marriage-count        ; 历史结婚对数
  birth-count           ; 历史出生人数
  
  ; --- 新增统计指标 ---
  total-marriage-age    ; 历史所有结婚者的年龄总和
  total-married-people  ; 历史结婚总人数 ( = marriage-count * 2)
]

breed [men man]
breed [women woman]

turtles-own [
  age
  wealth
  looks
  standard
  status          ; 0=single, 1=married
  partner
  weight-wealth   ; 价值观
]

to setup
  clear-all
  set marriage-count 0
  set birth-count 0
  set total-marriage-age 0
  set total-married-people 0
  
  create-men (initial-people / 2) [ 
    setxy random-xcor random-ycor 
    init-person "male" 
  ]
  
  create-women (initial-people / 2) [ 
    setxy random-xcor random-ycor 
    init-person "female" 
  ]
  
  reset-ticks
end

to init-person [gender]
  set shape "person"
  ifelse gender = "male" [ set color blue ] [ set color red ]
    
  set age 20 + random 10
  
  ; 正态分布财富
  set wealth random-normal 50 30
  if wealth < 0 [ set wealth 5 ]
  
  ; 正态分布颜值
  set looks random-normal 50 15
  if looks > 100 [ set looks 100 ]
  if looks < 0 [ set looks 0 ]
  
  ; 价值观偏好
  ifelse gender = "male" [
    set weight-wealth 0.2 + random-float 0.2
  ] [
    set weight-wealth 0.6 + random-float 0.2
  ]
  
  ; 正态分布标准
  set standard random-normal 60 20
  if standard > 100 [ set standard 100 ]
  if standard < 0 [ set standard 0 ]
  
  set status 0
  set partner nobody
end

to go
  if count turtles = 0 [ stop ]
  
  ask turtles [
    move
    aging
    compromise
    match
    reproduce
  ]
  
  do-plotting
  tick
end

to move
  rt random 40 - 20
  fd 1
end

to aging
  set age age + 0.2
  
  let decay-factor 0.01
  if age > 30 [ set decay-factor 0.05 ]
  
  set looks looks - decay-factor * (age / 10)
  if looks < 0 [ set looks 0 ]

  set wealth wealth * (1 + economic-growth + (random-float 0.02 - 0.01))
  
  ; 死亡逻辑 (5.x 写法)
  if age > 80 and random 100 < 10 [ 
    if partner != nobody [
      ask partner [ 
        set status 0 
        set partner nobody 
        ifelse breed = men [ set color blue ] [ set color red ]
      ]
    ]
    die 
  ]
end

to compromise
  if status = 0 and age > 30 [
    set standard standard - (social-pressure * 10)
    if standard < 0 [ set standard 0 ]
  ]
end

to match
  if status = 0 [
    let potential-mates other turtles-here with [status = 0 and breed != [breed] of myself]
    
    if any? potential-mates [
      let target one-of potential-mates
      
      ; 计算加权评分
      let score-for-target ([wealth] of target * weight-wealth) + ([looks] of target * (1 - weight-wealth))
      
      let target-weight-wealth [weight-wealth] of target
      let score-for-me (wealth * target-weight-wealth) + (looks * (1 - target-weight-wealth))
      
      if score-for-target >= standard and score-for-me >= [standard] of target [
        get-married target
      ]
    ]
  ]
end

to get-married [mate]
  if wealth > marriage-cost and [wealth] of mate > marriage-cost [
    set wealth wealth - marriage-cost
    ask mate [ set wealth wealth - marriage-cost ]
    
    set status 1
    set partner mate
    set color green
    
    ask mate [ 
      set status 1 
      set partner myself 
      set color green 
    ]
    
    ; --- 统计结婚数据 ---
    set marriage-count marriage-count + 1
    
    ; 记录两人当前的年龄
    set total-marriage-age total-marriage-age + age + [age] of mate
    set total-married-people total-married-people + 2
    
    create-link-with mate [ set color green ]
  ]
end

to reproduce
  if status = 1 and breed = women [
    if age > 22 and age < 40 [
      
      let mother-wealth wealth
      let father-wealth [wealth] of partner
      let family-wealth mother-wealth + father-wealth
      let actual-cost child-cost

      ; 富人投入更多成本
      if family-wealth * 0.1 > child-cost [
        set actual-cost family-wealth * 0.1
      ]
      
      if family-wealth > child-cost [
        if random 100 < 5 [ 
          
          let mother-looks looks
          let father-looks [looks] of partner
          let mother-weight weight-wealth
          let father-weight [weight-wealth] of partner

          hatch 1 [
            set shape "person"
            set age 0
            set status 0
            set partner nobody
            
            ifelse random 2 = 0 
              [ set breed men set color blue ] 
              [ set breed women set color red ]
            
            ; 财富继承 (消耗掉一部分，剩下给孩子)
            set wealth (actual-cost * 0.2)
            set wealth wealth + random-normal 0 2
            if wealth < 0 [ set wealth 0 ]
            
            ; 颜值遗传
            set looks (mother-looks + father-looks) / 2 + random-normal 0 5
            if looks > 100 [ set looks 100 ]
            if looks < 0 [ set looks 0 ]
            
            ; 价值观遗传
            set weight-wealth (mother-weight + father-weight) / 2 + (random-float 0.1 - 0.05)
            if weight-wealth > 1 [ set weight-wealth 1 ]
            if weight-wealth < 0 [ set weight-wealth 0 ]
            
            ; 标准遗传
            set standard 50 + random 40
            
            fd 1
            set birth-count birth-count + 1
          ]
          
          set wealth wealth - (actual-cost / 2)
          ask partner [ set wealth wealth - (actual-cost / 2) ]
        ]
      ]
    ]
  ]
end

to do-plotting
  ; --- 安全检查：没人就不画了，防止报错 ---
  if count turtles = 0 [ stop ]

  ; --- 图表1 ---
  ; 你的界面上必须有一个叫 "babies and marriage" 的图表
  set-current-plot "babies and marriage" 
  set-current-plot-pen "marriage"
  plot (count turtles with [status = 1] / count turtles) * 100 
  
  set-current-plot-pen "babies"
  plot birth-count

  ; --- 图表2 ---
  ; 你的界面上必须有一个叫 "Looks Stats" 的图表
  set-current-plot "Looks Stats" 
  set-current-plot-pen "avg-looks"
  plot mean [looks] of turtles
  
  ; --- 图表3 ---
  ; 你的界面上必须有一个叫 "Wealth Stats" 的图表
  set-current-plot "Wealth Stats" 
  set-current-plot-pen "avg-wealth"
  plot mean [wealth] of turtles

  ; --- 图表4 ---
  ; 你的界面上必须有一个叫 "Values Trend" 的图表
  set-current-plot "Values Trend"
  set-current-plot-pen "avg-money-weight"
  plot (mean [weight-wealth] of turtles) * 100
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
675
496
17
17
13.0
1
10
1
1
1
0
1
1
1
-17
17
-17
17
0
0
1
ticks
30.0

SLIDER
59
39
231
72
marriage-cost
marriage-cost
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
46
164
218
197
child-cost
child-cost
0
100
35
1
1
NIL
HORIZONTAL

SLIDER
42
236
214
269
economic-growth
economic-growth
0
0.1
0.015
0.005
1
NIL
HORIZONTAL

SLIDER
38
298
210
331
social-pressure
social-pressure
0
0.1
0.04
0.01
1
NIL
HORIZONTAL

PLOT
45
432
245
582
babies and marriage
NIL
NIL
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"marriage" 1.0 0 -2139308 true "" ""
"babies" 1.0 0 -8275240 true "" ""

BUTTON
812
89
885
122
初始化
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
821
161
908
194
开始运行
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
735
294
817
343
当前结婚率
(count turtles with [status = 1] / (count turtles + 0.001)) * 100
2
1
12

MONITOR
739
370
821
419
当前总人口
count turtles
2
1
12

PLOT
996
66
1196
216
Values Trend
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"avg-money-weight" 1.0 0 -6917194 true "" ""

PLOT
997
246
1197
396
Wealth Stats
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"avg-wealth" 1.0 0 -11085214 true "" ""

PLOT
1004
441
1204
591
Looks Stats
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"avg-looks" 1.0 0 -1664597 true "" ""

SLIDER
41
100
213
133
initial-people
initial-people
50
500
245
1
1
NIL
HORIZONTAL

MONITOR
734
450
830
499
平均初婚年龄
total-marriage-age / (total-married-people + 0.001)
17
1
12

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
