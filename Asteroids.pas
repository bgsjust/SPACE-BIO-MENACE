{$N-}
{ 'Space BIO Menace' is a space shooter done in one afternoon }
{ using borland Pascal 7.0                                    }
{                                                             }
{ It's a clone of the game Asteroids.                         }
{ Made by myself: Bruno Sousa in 2025                         }
{ You can freely use it in your projects, try to inprove it   }
{ Just give credit to the author!                             }
{ Next steps :                                                }
{ -Improve graphics                                           }
{ -Add sound fx and music                                     }
{ -Add power-ups                                              }
{ -Enemy Rebel/Rougue ships                                   }
{                                                             }
{ Happy coding!                                               }


program AsteroidsBPDOS;
uses crt;

const
  ScreenW = 320;
  ScreenH = 200;
  CenterX = 160;
  CenterY = 100;

  MaxAsteroids = 12;
  MaxParticles = 32;
  MaxExplosions = 8;

  MaxMissiles   = 8;
  MissileSpeed  = 6.0;
  MissileRange  = 170.0;  { max distance in pixels }

  MaxLives        = 3;
  MaxEnergy       = 100;
  EnergyDrainRate = 2;    { per frame while touching asteroid }
  ShipRadius      = 6;

  ShipPointCount = 40;
  ThrustPointCount = 12;

  STATE_PLAYING  = 0;
  STATE_GAMEOVER = 1;
  STATE_TITLE = 2;


type
  TPoint = record
    x, y : Integer;
  end;

  TVector = record
    x, y : Real;
  end;

  TShip = record
    pos, vel : TVector;
    angle    : Real;
    lives    : Integer;
    shield   : Integer;
  end;

  TAsteroid = record
    pos : TVector;
    vel : TVector;
    size: Integer; { 3 large, 2 medium, 1 small }
    active: Boolean;
  end;

  TMissile = record
    pos, vel : TVector;
    startPos : TVector;
    active  : Boolean;
  end;

  TParticle = record
    pos, vel : TVector;
    life    : Integer;
    active  : Boolean;
  end;


  TExplosion = record
     Particles : array[1..MaxParticles] of TParticle;
     active :boolean;
  end;


 TSegLine = record
    x1, y1, x2, y2 : Integer;
  end;

const
  Font8Seg : array[0..35] of Byte = (
    { 0 to 9 }
    191, { '0' = 10111111 }
      6, { '1' = 00000110 }
     91, { '2' = 01011011 }
     79, { '3' = 01001111 }
    102, { '4' = 01100110 }
    109, { '5' = 01101101 }
    125, { '6' = 01111101 }
      7, { '7' = 00000111 }
    127, { '8' = 01111111 }
    111, { '9' = 01101111 }

    { A to Z }
     119, { 'A' = 01110111 }
     127, { 'B' = 01111111 }  { looks like b }
      57, { 'C' = 00111001 }
      63, { 'D' = 00111111 }  { looks like d }
     121, { 'E' = 01111001 }
     113, { 'F' = 01110001 }
      61, { 'G' = 00111101 }                     {    0    }
     118, { 'H' = 01110110 }                     {  -----  }
      48, { 'I' = 00110000 }                     {5 |   | 1}
      30, { 'J' = 00011110 }                     {  | 6 |  }
     118, { 'K' = 01110110 }  { stylized }       {  -----  }
      56, { 'L' = 00111000 }                     {4 |   | 2}
      55, { 'M' = 00110111 }  { stylized }       {  |   |  }
      55, { 'N' = 00110111 }  { stylized }       {  -----  }
      63, { 'O' = 00111111 }                     {    3    }
      115,{ 'P' = 01110011 }                     {7-diagnl.}
      63, { 'Q' = 00111111 }
     119, { 'R' = 01110111 }
     109, { 'S' = 01101101 }
      49, { 'T' = 00110001 }
      62, { 'U' = 00111110 }
     176, { 'V' = 10110000 }
      62, { 'W' = 00111110 }  { stylized }
     118, { 'X' = 01110110 }
     110, { 'Y' = 01100110 }
      91  { 'Z' = 01011011 }
  );


 Segments : array[0..7] of TSegLine = (

    (x1:-6; y1:-10; x2:  6; y2:-10), { bit 0 TOP }
    (x1: 6; y1:-10; x2:  6; y2:  0), { bit 1 UPPER RIGHT }
    (x1: 6; y1:  0; x2:  6; y2: 10), { bit 2 LOWER RIGHT }
    (x1:-6; y1: 10; x2:  6; y2: 10), { bit 3 BOTTOM }
    (x1:-6; y1:  0; x2: -6; y2: 10), { bit 4 LOWER LEFT }
    (x1:-6; y1:-10; x2: -6; y2:  0), { bit 5 UPPER LEFT }
    (x1:-6; y1:  0; x2:  6; y2:  0), { bit 6 MIDDLE }
    (x1:-6; y1: 10; x2:  6; y2:-10)  { bit 7 DIAGONAL / EXTRA }
  );


const
 ShipShape : array[1..ShipPointCount] of TPoint = (
    (x:  7; y: 0),
    (x:  6; y: 1),
    (x:  6; y: -1),
    (x:  5; y: 1),
    (x:  5; y: -1),
    (x: 4; y:  2),
    (x: 4; y:  -2),           {    --------            }
    (x: 3; y:  3),            {    87654321012345678   }
    (x: 3; y:  -3),           {          ooooo        7}
    (x: 2; y:  4),            {           oo          6}
    (x: 2; y:  -4),           {          o  o         5}
    (x: 1; y:  5),            {          o   o        4}
    (x: 1; y:  -5),           {          o    o       3}
    (x: 0; y:  6),            {          o     o      2}
    (x: 0; y:  -6),           {           o     oo    1}
    (x: 0; y:  7),            {           o       ooo 0}
    (x: 0; y:  -7),           {           o     oo   -1}
    (x: -1; y: 6),            {          o     o     -2}
    (x: -1; y: -6),           {          o    o      -3}
    (x: -1; y: 7),            {          o   o       -4}
    (x: -1; y: -7),           {          o  o        -5}
    (x: -1; y: 1),            {           oo         -6}
    (x: -1; y: 0),            {          ooooo       -7}
    (x: -1; y: -1),
    (x: -2; y: 5),
    (x: -2; y: 4),
    (x: -2; y: 3),
    (x: -2; y: 2),
    (x: -2; y: -5),
    (x: -2; y: -4),
    (x: -2; y: -3),
    (x: -2; y: -2),
    (x:  1; y:  7),
    (x:  1; y: -7),
    (x:  2; y:  7),
    (x:  2; y: -7),
    (x:  -2; y:  7),
    (x:  -2; y: -7),
    (x:  8; y: 0),
    (x:  9; y: 0));
                              { Thruster }
   ThrustShape : array[1..ThrustPointCount] of TPoint = (
    (x: -4; y:  3),
    (x: -4; y:  4),
    (x: -4; y:  5),
    (x: -4; y: -3),
    (x: -4; y: -4),
    (x: -4; y: -5),
    (x: -5; y: 4),
    (x: -5; y: 5),
    (x: -5; y: -4),
    (x: -5; y: -5),
    (x: -6; y: 5),
    (x: -6; y: -5)
  );

var
  Ship : TShip;
  Ast  : array[1..MaxAsteroids] of TAsteroid;
  {Missile : TMissile;}
  Missiles : array[1..MaxMissiles] of TMissile;

  {Particles : array[1..MaxParticles] of TParticle;}


  Explosions : array[1..MaxExplosions] of TExplosion;


  Score, Level : LongInt;
  Lives   : Integer;
  Energy  : Integer;
  ShipExplodeTimer : Integer;
  Thrusting : Boolean;
  GameState : Integer;

const
  PI = 3.141592653589793;

function DegToRad(d: Real): Real;
begin
   DegToRad := d * PI / 180.0;
end;




{ ---------------- VGA ---------------- }


procedure SetMode13h;
begin
  asm
    mov ax, $0013
    int $10
  end;
end;

procedure TextMode;
begin
  asm
    mov ax, $0003
    int $10
  end;
end;

procedure PutPixel(x,y:Integer; c:Byte);
begin
  if (x<0) or (x>=320) or (y<0) or (y>=200) then Exit;
  Mem[SegA000:y*320+x] := c;
end;


procedure DrawLine(x1, y1, x2, y2: Integer; c: Byte);
var
  dx, dy  : Integer;
  sx, sy  : Integer;
  err, e2 : Integer;
begin
  dx := Abs(x2 - x1);
  dy := Abs(y2 - y1);

  if x1 < x2 then sx := 1 else sx := -1;
  if y1 < y2 then sy := 1 else sy := -1;

  err := dx - dy;

  while True do
  begin
    PutPixel(x1, y1, c);

    if (x1 = x2) and (y1 = y2) then
      Exit;

    e2 := err shl 1;

    if e2 > -dy then
    begin
      err := err - dy;
      x1 := x1 + sx;
    end;

    if e2 < dx then
    begin
      err := err + dx;
      y1 := y1 + sy;
    end;
  end;
end;


{ ---------------- FONT ---------------- }

function GetFontByte(ch: Char): Byte;
begin
  if (ch >= '0') and (ch <= '9') then
    GetFontByte := Font8Seg[Ord(ch) - Ord('0')]
  else
  if (ch >= 'A') and (ch <= 'Z') then
    GetFontByte := Font8Seg[10 + Ord(ch) - Ord('A')]
  else
    GetFontByte := 0;
end;


procedure DrawChar8Seg(x, y:integer; scale: Real; ch: Char; col: Byte);
var
  mask: Byte;
  s: Integer;
begin
  mask := GetFontByte(ch);

  for s := 0 to 7 do
    if (mask and (1 shl s)) <> 0 then
      DrawLine(
        x + round(Segments[s].x1 * scale),
        y + round(Segments[s].y1 * scale),
        x + round(Segments[s].x2 * scale),
        y + round(Segments[s].y2 * scale),
        col
      );
end;

procedure DrawChar8SegR(x, y:integer; scale: real; ch: Char; col: Byte);
var
  mask: Byte;
  s: Integer;
begin
  mask := GetFontByte(ch);

  for s := 0 to 7 do
    if (mask and (1 shl s)) <> 0 then
      DrawLine(
        x + round(Segments[s].x1 * scale),
        y + round(Segments[s].y1 * scale),
        x + round(Segments[s].x2 * scale),
        y + round(Segments[s].y2 * scale),
        col
      );
end;





function TextWidth8Seg(scale: Integer; s: String): Integer;
begin
  TextWidth8Seg := (Length(s)-1) * scale * 14;
end;



procedure DrawStringXCenter(y, scale: Integer; s: String; col: Byte);
var
  i: Integer;
  cx: Integer;
begin
  cx := (ScreenW - TextWidth8Seg(Scale, s)) div 2;
  for i := 1 to Length(s) do
  begin
    DrawChar8Seg(cx, y, scale, UpCase(s[i]), col);
    Inc(cx, scale * 14); { character spacing }
  end;
end;


procedure DrawString8Seg(x, y:integer; scale: real; s: String; col: Byte);
var
  i: Integer;
  cx: Integer;
begin
  cx := x;

  for i := 1 to Length(s) do
  begin
    DrawChar8SegR(cx, y, scale, UpCase(s[i]), col);
    Inc(cx, round(scale * 14)+1); { character spacing }
  end;
end;

procedure ClearScreen;
begin
  FillChar(Mem[SegA000:0], 64000, 0);
end;


{ ------------- Math / Physics ------------ }

procedure Wrap(var p:TVector);
begin
  if p.x<0 then p.x:=319;
  if p.x>319 then p.x:=0;
  if p.y<0 then p.y:=199;
  if p.y>199 then p.y:=0;
end;

function Dist(a,b:TVector):Real;
begin
  Dist := Sqrt(Sqr(a.x-b.x)+Sqr(a.y-b.y));
end;

{We rotate each pixel point, not the whole shape.}
procedure RotatePoint(px, py: Integer; angle: Real; var rx, ry: Integer);
var
  ca, sa: Real;
begin
  ca := Cos(DegToRad(angle));
  sa := Sin(DegToRad(angle));

  rx := Round(px * ca - py * sa);
  ry := Round(px * sa + py * ca);
end;

{ ------------- Ship ---------------- }


procedure ClampSpeed(maxv: Real);
var s: Real;
begin
  s := Sqrt(Sqr(Ship.vel.x) + Sqr(Ship.vel.y));
  if s > maxv then
  begin
    Ship.vel.x := Ship.vel.x / s * maxv;
    Ship.vel.y := Ship.vel.y / s * maxv;
  end;
end;

procedure InitShip;
begin
  Ship.pos.x := CenterX;
  Ship.pos.y := CenterY;
  Ship.vel.x := 0;
  Ship.vel.y := 0;
  Ship.angle := 270;
  Ship.lives := 3;
  Ship.shield := 100;
end;


procedure DrawShipPixel(thrustOn: Boolean);
var
  i, rx, ry: Integer;
begin
  { ship outline }
  for i := 1 to ShipPointCount do
  begin
    RotatePoint(
      ShipShape[i].x,
      ShipShape[i].y,
      Ship.angle,
      rx, ry
    );

    PutPixel(
      Round(Ship.pos.x) + rx,
      Round(Ship.pos.y) + ry,
      15   { white }
    );
  end;

  { engine thrust }
  if thrustOn then
    for i := 1 to ThrustPointCount do
    begin
      RotatePoint(
        ThrustShape[i].x,
        ThrustShape[i].y,
        Ship.angle,
        rx, ry
      );

      PutPixel(
        Round(Ship.pos.x) + rx,
        Round(Ship.pos.y) + ry,
        12   { orange/red }
      );
    end;
end;


procedure MoveShip;
begin
  Ship.pos.x := Ship.pos.x + Ship.vel.x;
  Ship.pos.y := Ship.pos.y + Ship.vel.y;
  Wrap(Ship.pos);

  Ship.vel.x := Ship.vel.x * 0.999;
  Ship.vel.y := Ship.vel.y * 0.999;
end;


procedure ExplodeShip;
var
  e,i: Integer;
  a: Real;
begin
  for e := 1 to MaxExplosions do begin
     if Explosions[e].active = false then begin
       Explosions[e].active := true;
       for i := 1 to MaxParticles do
       begin
          Explosions[e].Particles[i].active := True;
          Explosions[e].Particles[i].pos := Ship.pos;
          a := Random * 2 * PI;
          Explosions[e].Particles[i].vel.x := Cos(a) * (Random * 2 + 1);
          Explosions[e].Particles[i].vel.y := Sin(a) * (Random * 2 + 1);
          Explosions[e].Particles[i].life := 20 + Random(20);
       end;
       exit;
     end;
  end;

end;

{0.98 - very light brake
 0.95 - good arcade feel
 0.90 - strong brake}
procedure BrakeShip(factor: Real);
begin
  Ship.vel.x := Ship.vel.x * factor;
  Ship.vel.y := Ship.vel.y * factor;
end;

{ check ship colision that will drain energy bar }
procedure CheckShipAsteroidCollision;
var
  i: Integer;
  d: Real;
begin
  if ShipExplodeTimer > 0 then Exit; { invulnerable }

  for i := 1 to MaxAsteroids do
    if Ast[i].active then
    begin
      d := Dist(Ship.pos, Ast[i].pos);

      if d < (ShipRadius + Ast[i].size * 5) then
      begin
        { drain energy gradually }
        Dec(Energy, EnergyDrainRate);

        if Energy <= 0 then
        begin
          { ship destroyed }
          Dec(Lives);
          ExplodeShip;
          ShipExplodeTimer := 40;
          Energy := MaxEnergy;
          Ship.pos.x := CenterX;
          Ship.pos.y := CenterY;
          Ship.vel.x := 0;
          Ship.vel.y := 0;

          if Lives < 0 then
          begin
            {TextMode;
            WriteLn('GAME OVER');
            Halt;}
            GameState := STATE_GAMEOVER;
          end;
        end;
      end;
    end;
end;

procedure UpdateExplosionTimer;
begin
  if ShipExplodeTimer > 0 then Dec(ShipExplodeTimer);
end;


procedure DrawEnergyBar;
var
  i, w: Integer;
begin
  w := (Energy * 60) div MaxEnergy;

  for i := 0 to w do
    PutPixel(10 + i, 10, 10); { green }

  for i := w to 60 do
    PutPixel(10 + i, 10, 4);  { red }
end;

{ ------------- Missile ---------------- }


procedure Init_Missiles;
var
i:integer;
begin
   for i := 1 to MaxMissiles do Missiles[i].active := false;
end;


procedure FireMissile;
var
  i: Integer;
begin
  for i := 1 to MaxMissiles do
    if not Missiles[i].active then
    begin
      Missiles[i].active := True;
      Missiles[i].pos := Ship.pos;
      Missiles[i].startPos := Ship.pos;
      Missiles[i].vel.x := Cos(DegToRad(Ship.angle)) * MissileSpeed;
      Missiles[i].vel.y := Sin(DegToRad(Ship.angle)) * MissileSpeed;
      Exit;
    end;
end;

procedure MoveMissiles;
var
  i: Integer;
begin
  for i := 1 to MaxMissiles do
    if Missiles[i].active then
    begin
      Missiles[i].pos.x := Missiles[i].pos.x + Missiles[i].vel.x;
      Missiles[i].pos.y := Missiles[i].pos.y + Missiles[i].vel.y;

      {Wrap(Missiles[i].pos);}

      if (Missiles[i].pos.x<0) or (Missiles[i].pos.y<0) or
         (Missiles[i].pos.x>ScreenW) or (Missiles[i].pos.y>ScreenH) then
         Missiles[i].active := False;

      { distance traveled }
      if Dist(Missiles[i].pos, Missiles[i].startPos) > MissileRange then
         Missiles[i].active := False;
    end;
end;

procedure DrawMissiles;
var
  i: Integer;
begin
  for i := 1 to MaxMissiles do
    if Missiles[i].active then
      PutPixel(
        Round(Missiles[i].pos.x),
        Round(Missiles[i].pos.y),
        14
      );
end;

{ ------------- Asteroids ---------------- }

procedure Init_Asteroids;
var i:Integer;
begin
  for i:=1 to MaxAsteroids do
    begin
      Ast[i].active := false;
    end;
end;

procedure SpawnAsteroid(asts, size:Integer);
var
   a,i:Integer;
   boundery:byte;
begin
  a := 1;
  for i:=1 to MaxAsteroids do
     begin
        if not (Ast[i].active) then
           begin
              Ast[i].active := True;
              Ast[i].size := size;


              {spawn at random screen corner}
              boundery := random(4);
              case boundery of
              0:begin
                 Ast[i].pos.x := Random(100); {top left}
                 Ast[i].pos.y := Random(100);
                end;
              1:begin
                 Ast[i].pos.x := 200 + Random(120); {top right}
                 Ast[i].pos.y := Random(100);
                end;
              2:begin
                 Ast[i].pos.x := Random(100); {bottom left}
                 Ast[i].pos.y := 100 + Random(100);
                end;
              3:begin
                 Ast[i].pos.x := 200 + Random(120); {bottom rigth}
                 Ast[i].pos.y := 100 + Random(100);
                end;
              end;

              Ast[i].vel.x := Random*2-1;
              Ast[i].vel.y := Random*2-1;
              inc(a);
            end;
        if a > asts then exit;
     end;
end;

procedure SpawnAsteroidxy(x, y:real; asts, size:Integer);
var
   a,i:Integer;
begin
  a := 1;
  for i:=1 to MaxAsteroids do
     begin
        if not (Ast[i].active) then
           begin
              Ast[i].active := True;
              Ast[i].size := size;
              Ast[i].pos.x := x;
              Ast[i].pos.y := y;
              Ast[i].vel.x := Random*2-1;
              Ast[i].vel.y := Random*2-1;
              inc(a);
            end;
        if a > asts then exit;
     end;
end;


procedure ExplodeAsteroid(asteroid:Tasteroid);
var
  e,i: Integer;
  a: Real;
begin
  for e := 1 to MaxExplosions do begin
     if Explosions[e].active = false then begin
       Explosions[e].active := true;
       for i := 1 to MaxParticles do
          begin
             Explosions[e].Particles[i].active := True;
             Explosions[e].Particles[i].pos := asteroid.pos;
             a := Random * 2 * PI;
             Explosions[e].Particles[i].vel.x := Cos(a) * (Random * 2 + 1);
             Explosions[e].Particles[i].vel.y := Sin(a) * (Random * 2 + 1);
             Explosions[e].Particles[i].life := 20 + Random(20);
          end;
       exit;
     end;
  end;
end;


procedure CheckMissileAsteroidCollisions;
var
  i, j: Integer;
begin
  for i := 1 to MaxMissiles do begin
    if Missiles[i].active then begin
      for j := 1 to MaxAsteroids do begin
        if Ast[j].active then begin
          if Dist(Missiles[i].pos, Ast[j].pos) < (Ast[j].size * 5 + 2) then
          begin
            Missiles[i].active := False;
            Score := Score + 100;

            if Ast[j].size > 1 then
            begin
              Ast[j].active := False;
              ExplodeAsteroid(Ast[j]);

              SpawnAsteroidxy(Ast[j].pos.x,Ast[j].pos.y,1,Ast[j].size - 1);
              SpawnAsteroidxy(Ast[j].pos.x,Ast[j].pos.y,1,Ast[j].size - 1);
            end
            else
               begin
                  Ast[j].active := False;
                  ExplodeAsteroid(Ast[j]);
                  SpawnAsteroid(1,3);
               end;
          end;
        end;
      end;
    end;
  end;
end;

procedure MoveAsteroids;
var i,j:Integer;
begin
  for i:=1 to MaxAsteroids do
    if Ast[i].active then
    begin
      Ast[i].pos.x := Ast[i].pos.x + Ast[i].vel.x;
      Ast[i].pos.y := Ast[i].pos.y + Ast[i].vel.y;
      Wrap(Ast[i].pos);
    end;
end;

procedure DrawAsteroids;
var i,r,a:Integer;
begin
  for i:=1 to MaxAsteroids do begin
    if Ast[i].active then begin
      a:=0;
      while a<=360 do
      begin
        r := Ast[i].size*5 - (random(3));
        PutPixel(
          Round(Ast[i].pos.x+Cos(DegToRad(a))*r),
          Round(Ast[i].pos.y+Sin(DegToRad(a))*r),
          10
        );
        a := a + 30;
      end;
    end;
  end;
end;

{ ------------- Particles ---------------- }

procedure UpdateParticles;
var
  e,i: Integer;
  some_particles_alive : boolean;
begin
  for e := 1 to MaxExplosions do begin
     if Explosions[e].active = true then begin
        some_particles_alive := false;
        for i := 1 to MaxParticles do begin

           if Explosions[e].Particles[i].active then
           begin
              Explosions[e].Particles[i].pos.x := Explosions[e].Particles[i].pos.x + Explosions[e].Particles[i].vel.x;
              Explosions[e].Particles[i].pos.y := Explosions[e].Particles[i].pos.y + Explosions[e].Particles[i].vel.y;
              Dec(Explosions[e].Particles[i].life);
              PutPixel(Round(Explosions[e].Particles[i].pos.x),Round(Explosions[e].Particles[i].pos.y),12);
              if Explosions[e].Particles[i].life <= 0 then Explosions[e].Particles[i].active := False
              else some_particles_alive := true;
           end;
        end;
        if some_particles_alive = false then Explosions[e].active := false;
     end;
  end;
end;



function IntStr(i:longint):string;
var stx:string[11];
begin
   str(i,stx);
   intstr := stx;
end;

{ ------------- Main ---------------- }


Procedure DrawGameOverScreen;
begin
  { Title }
  if GameState = STATE_TITLE then DrawStringXCenter(30,1,'SPACE BIO MENACE',15)
  else DrawStringXCenter(30,2,'GAME OVER',15);
  { Score }
  if GameState <> STATE_TITLE then DrawStringXCenter(80,1,'SCORE '+IntStr(Score),10);
  { Options }
  DrawStringXCenter(120,1,'S START   E EXIT',12);
  { Credits }
  DrawStringXCenter(170,1,'DEVELOPER BRUNO SOUSA',12);
end;



Procedure ResetGame;
begin
  InitShip;
  Init_Asteroids;
  Init_Missiles;
  Score := 0;
  Level := 1;
  GameState := STATE_PLAYING;
  Lives  := MaxLives;
  Energy := MaxEnergy;
  ShipExplodeTimer := 40;
  SpawnAsteroid(1,3);
  SpawnAsteroid(1,3);
  SpawnAsteroid(1,3);

end;

procedure HandleGameOverInput;
var
  ch: Char;
begin
  if not KeyPressed then Exit;

  ch := ReadKey;

  case ch of
    's','S':
      begin
        ResetGame;              { you already have or will define this }
        GameState := STATE_PLAYING;
        {FlushKeys;}
      end;

    'e','E', #27:
      begin
        TextMode;
        Halt;
      end;
  end;
end;


procedure Input;
var
key:char;

begin
  if KeyPressed then begin
    case readkey of
      #75: Ship.angle := Ship.angle - 10; { left }
      #77: Ship.angle := Ship.angle + 10; { right }
      #72: begin
             Ship.vel.x := Ship.vel.x + Cos(DegToRad(Ship.angle))*0.3;
             Ship.vel.y := Ship.vel.y + Sin(DegToRad(Ship.angle))*0.3;
             Thrusting := True;
           end;
      #80: BrakeShip(0.95);
      ' ': FireMissile;
      {'h','H': begin
                 Ship.pos.x:=Random(320);
                 Ship.pos.y:=Random(200);
               end;}
      #27: begin TextMode; Halt; end;
    end;
  end;
end;



{ ------ MAIN ------  }

begin
  Randomize;
  SetMode13h;


  ResetGame;

  GameState := STATE_TITLE;

  repeat

    Case GameState of

      STATE_PLAYING:
       begin
        Thrusting := false;
        ClearScreen;
        Input;
        MoveShip;
        MoveMissiles;
        MoveAsteroids;

        DrawShipPixel(Thrusting);
        DrawMissiles;
        DrawAsteroids;

        CheckMissileAsteroidCollisions;

        UpdateExplosionTimer;
        CheckShipAsteroidCollision;

        UpdateParticles;

        DrawEnergyBar;
        DrawString8Seg(260, 10, 0.5, 'LIVES:'+intstr(lives), 12);
       end;
      STATE_GAMEOVER, STATE_TITLE:
       begin
        {UpdateGameOverAsteroids;}
        ClearScreen;
        MoveAsteroids;
        DrawAsteroids;
        DrawGameOverScreen;
        HandleGameOverInput;
       end;
    end;

    Delay(200);

  until False;
end.
