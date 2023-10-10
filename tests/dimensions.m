fullpath = mfilename("fullpath");
path_examples = fileparts(fullpath);
path_bds = fileparts(path_examples);
path_locate = fullfile(path_bds, "tests", "private");

cd(path_locate)
locate_matcutest()

dim = 10;
s.mindim = dim;
s.maxdim = dim;
secup(s)

% s = ["ARGTRIGLS",...
%      "BROWNAL",...
%      "COATING",...
%      "DIAMON2DLS",...
%      "DIAMON3DLS",...
%      "DMN15102LS",...
%      "DMN15103LS",...
%      "DMN15332LS",...
%      "DMN15333LS",...
%      "DMN37142LS",...
%      "DMN37143LS",...
%      "ERRINRSM",...
%      "HYDC20LS",...
%      "LRA9A",...
%      "LRCOVTYPE",...
%      "LUKSAN12LS",...
%      "LUKSAN14LS",...
%      "LUKSAN17LS",...
%      "LUKSAN21LS",...
%      "LUKSAN22LS",...
%      "MANCINO",...
%      "PENALTY2",...
%      "PENALTY3",...
%      "VARDIM"];
% 
% for i = 1:length(s)
%     p = macup(s(i));
%     dim = length(p.x0);
%     fprintf("The dimension of the problem %s is %d\n", s(i), dim);
% end

